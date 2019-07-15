import HSCryptoKit

class SwapInitiator {
    enum SwapInitiatorError: Error {
        case swapNotAgreed
        case bailTransactionAlreadySent
        case redeemTransactionAlreadySent
        case bailTransactionCouldNotBeRestored
    }

    private let initiatorBlockchain: ISwapBlockchain
    private let responderBlockchain: ISwapBlockchain
    private let storage: SwapStorage
    var swap: Swap

    init(initiatorBlockchain: ISwapBlockchain, responderBlockchain: ISwapBlockchain, storage: SwapStorage, swap: Swap) {
        self.initiatorBlockchain = initiatorBlockchain
        self.responderBlockchain = responderBlockchain
        self.storage = storage
        self.swap = swap
    }

    static func generate(initiatorBlockchain: ISwapBlockchain, responderBlockchain: ISwapBlockchain, storage: SwapStorage, rate: Double, amount: Double) throws -> SwapInitiator {
        let id = RandomHelper.shared.randomBytes(length: 32)
        let secret = RandomHelper.shared.randomBytes(length: 32)
        let refundPublicKey = try initiatorBlockchain.changePublicKey()
        let redeemPublicKey = try responderBlockchain.receivePublicKey()

        let swap = Swap(
                id: id.reduce("") { $0 + String(format: "%02x", $1) }, state: Swap.State.requested,
                initiator: true, initiatorCoinCode: initiatorBlockchain.coinCode, responderCoinCode: responderBlockchain.coinCode,
                rate: rate, amount: amount,
                secretHash: CryptoKit.sha256(secret), secret: secret,
                initiatorTimestamp: nil, responderTimestamp: nil,
                refundPKId: refundPublicKey.id, redeemPKId: redeemPublicKey.id,
                initiatorRefundPKH: refundPublicKey.keyHash, initiatorRedeemPKH: redeemPublicKey.keyHash,
                responderRefundPKH: nil, responderRedeemPKH: nil
        )

        storage.add(swap: swap)

        return SwapInitiator(initiatorBlockchain: initiatorBlockchain, responderBlockchain: responderBlockchain, storage: storage, swap: swap)
    }

    func onResponderAgree() throws {
        try bail()
        try watchResponderBail()
    }

    func triggerWatchers() throws {
        switch swap.state {
        case .initiatorBailed:
            try watchResponderBail()
        default: ()
        }
    }

    func triggerTxSends() throws {
        switch swap.state {
        case .responderBailed:
            guard let txDetails = swap.responderBailTransaction else {
                throw SwapInitiatorError.bailTransactionCouldNotBeRestored
            }

            try redeem(from: try responderBlockchain.bailTransaction(from: txDetails))
        default: ()
        }
    }

    private func bail() throws {
        guard swap.state == .requested else {
            throw SwapInitiatorError.bailTransactionAlreadySent
        }

        guard let responderRedeemPKH = swap.responderRedeemPKH, let initiatorTimestamp = swap.initiatorTimestamp else {
            throw SwapInitiatorError.swapNotAgreed
        }

        _ = try initiatorBlockchain.sendBailTransaction(
                withRedeemKeyHash: responderRedeemPKH, refundKeyHash: swap.initiatorRefundPKH,
                secretHash: swap.secretHash, timestamp: initiatorTimestamp, amount: swap.amount
        )

        swap.state = .initiatorBailed
        storage.update(swap: swap)
    }

    private func watchResponderBail() throws {
        guard let responderRefundPKH = swap.responderRefundPKH, let responderTimestamp = swap.responderTimestamp else {
            throw SwapInitiatorError.swapNotAgreed
        }

        responderBlockchain.watchBailTransaction(
                withRedeemKeyHash: swap.initiatorRedeemPKH, refundKeyHash: responderRefundPKH,
                secretHash: swap.secretHash, timestamp: responderTimestamp
        )
    }

    private func redeem(from bailTransaction: IBailTransaction) throws {
        guard swap.state == .responderBailed else {
            throw SwapInitiatorError.redeemTransactionAlreadySent
        }

        guard let secret = swap.secret, let redeemPKId = swap.redeemPKId,
              let responderRefundPKH = swap.responderRefundPKH, let responderTimestamp = swap.responderTimestamp else {
            throw SwapInitiatorError.swapNotAgreed
        }

        try responderBlockchain.sendRedeemTransaction(
                from: bailTransaction,
                withRedeemKeyHash: swap.initiatorRedeemPKH, redeemPKId: redeemPKId, refundKeyHash: responderRefundPKH,
                secret: secret, secretHash: swap.secretHash, timestamp: responderTimestamp
        )
        
        swap.state = .initiatorRedeemed
        storage.update(swap: swap)
    }

}

extension SwapInitiator: ISwapBlockchainDelegate {

    func onBailTransactionReceived(bailTransaction: IBailTransaction) {
        guard swap.state == .initiatorBailed else {
            return
        }

        guard let responderBailTransaction = try? responderBlockchain.data(from: bailTransaction) else {
            return
        }

        swap.state = .responderBailed
        swap.responderBailTransaction = responderBailTransaction
        storage.update(swap: swap)

        try? redeem(from: bailTransaction)
    }

    func onRedeemTransactionReceived(redeemTransaction: IRedeemTransaction) {
    }

}
