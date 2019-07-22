import Foundation

class SwapResponder {
    enum SwapResponderError: Error {
        case swapNotAgreed
        case bailTransactionAlreadySent
        case bailTransactionCouldNotBeRestored
        case redeemTransactionAlreadySent
    }

    private let initiatorBlockchain: ISwapBlockchain
    private let responderBlockchain: ISwapBlockchain
    private let storage: ISwapStorage
    var swap: Swap

    init(initiatorBlockchain: ISwapBlockchain, responderBlockchain: ISwapBlockchain, storage: ISwapStorage, swap: Swap) {
        self.initiatorBlockchain = initiatorBlockchain
        self.responderBlockchain = responderBlockchain
        self.storage = storage
        self.swap = swap
    }

    private func bail() throws -> IBailTransaction {
        guard swap.state == .initiatorBailed else {
            throw SwapResponderError.bailTransactionAlreadySent
        }

        guard let responderRefundPKH = swap.responderRefundPKH, let responderTimestamp = swap.responderTimestamp else {
            throw SwapResponderError.swapNotAgreed
        }

        let bailTransaction = try responderBlockchain.sendBailTransaction(
                withRedeemKeyHash: swap.initiatorRedeemPKH, refundKeyHash: responderRefundPKH,
                secretHash: swap.secretHash, timestamp: responderTimestamp, amount: swap.amount * swap.rate
        )

        swap.state = Swap.State.responderBailed
        swap.responderBailTransaction = try responderBlockchain.data(from: bailTransaction)
        storage.update(swap: swap)

        return bailTransaction
    }

    private func watchInitiatorBail() throws {
        guard let responderRedeemPKH = swap.responderRedeemPKH, let initiatorTimestamp = swap.initiatorTimestamp else {
            throw SwapResponderError.swapNotAgreed
        }

        initiatorBlockchain.watchBailTransaction(
                withRedeemKeyHash: responderRedeemPKH, refundKeyHash: swap.initiatorRefundPKH,
                secretHash: swap.secretHash, timestamp: initiatorTimestamp
        )
    }

    private func watchInitiatorRedeem() throws {
        guard let txDetails = swap.responderBailTransaction else {
            throw SwapResponderError.bailTransactionCouldNotBeRestored
        }

        let bailTransaction = try responderBlockchain.bailTransaction(from: txDetails)
        try responderBlockchain.watchRedeemTransaction(fromTransaction: bailTransaction)
    }

    private func redeem() throws {
        guard swap.state == .initiatorRedeemed else {
            throw SwapResponderError.redeemTransactionAlreadySent
        }

        guard let secret = swap.secret, let redeemPKId = swap.redeemPKId,
              let bailTransactionData = swap.initiatorBailTransaction, let bailTransaction = try? initiatorBlockchain.bailTransaction(from: bailTransactionData),
              let responderRedeemPKH = swap.responderRedeemPKH, let initiatorTimestamp = swap.initiatorTimestamp else {
            throw SwapResponderError.swapNotAgreed
        }

        try initiatorBlockchain.sendRedeemTransaction(
                from: bailTransaction,
                withRedeemKeyHash: responderRedeemPKH, redeemPKId: redeemPKId, refundKeyHash: swap.initiatorRefundPKH,
                secret: secret, secretHash: swap.secretHash, timestamp: initiatorTimestamp
        )

        swap.state = .responderRedeemed
        storage.update(swap: swap)
    }

}

extension SwapResponder: ISwapResponder {

    func proceedNext() throws {
        switch swap.state {
        case .responded:
            try watchInitiatorBail()
        case .initiatorBailed:
            _ = try bail()
            try watchInitiatorRedeem()
        case .responderBailed:
            try watchInitiatorRedeem()
        case .initiatorRedeemed:
            try redeem()
        default: ()
        }
    }

    func start() throws {
        guard swap.state == .responded else {
            return
        }

        try watchInitiatorBail()
    }

}

extension SwapResponder: ISwapBlockchainDelegate {

    func onBailTransactionReceived(bailTransaction: IBailTransaction) {
        guard swap.state == .responded else {
            return
        }

        swap.state = Swap.State.initiatorBailed
        swap.initiatorBailTransaction = try? initiatorBlockchain.data(from: bailTransaction)
        storage.update(swap: swap)

        guard let _ = try? bail() else {
            return
        }

        try? watchInitiatorRedeem()
    }

    func onRedeemTransactionReceived(redeemTransaction: IRedeemTransaction) {
        guard swap.state == .responderBailed else {
            return
        }

        swap.state = .initiatorRedeemed
        swap.secret = redeemTransaction.secret
        storage.update(swap: swap)

        try? redeem()
    }

}
