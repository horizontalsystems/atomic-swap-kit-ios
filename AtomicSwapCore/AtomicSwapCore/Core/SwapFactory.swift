import HSCryptoKit

class SwapFactory {
    enum FactoryError: Error {
        case blockchainNotSupported
        case swapNotFound
    }

    let storage: ISwapStorage
    var blockchainCreators = [String: ISwapBlockchainCreator]()

    init(storage: ISwapStorage) {
        self.storage = storage
    }

}

extension SwapFactory : ISwapFactory {

    func register(blockchainCreator: ISwapBlockchainCreator, forCoin coin: String) {
        blockchainCreators[coin] = blockchainCreator
    }

    func unregister(coin: String) {
        blockchainCreators.removeValue(forKey: coin)
    }

    func blockchain(from coinCode: String) throws -> ISwapBlockchain {
        guard let creator = blockchainCreators[coinCode] else {
            throw FactoryError.blockchainNotSupported
        }

        return try creator.create()
    }

    func swap(initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double) throws -> Swap {
        let initiatorBlockchain = try blockchain(from: initiatorCoinCode)
        let responderBlockchain = try blockchain(from: responderCoinCode)

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
        return swap
    }

    func swap(fromRequestId id: String, initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double, initiatorRefundPKH: Data, initiatorRedeemPKH: Data, secretHash: Data) throws -> Swap {
        let initiatorBlockchain = try blockchain(from: initiatorCoinCode)
        let responderBlockchain = try blockchain(from: responderCoinCode)

        let refundPKH = try responderBlockchain.changePublicKey()
        let redeemPKH = try initiatorBlockchain.receivePublicKey()
        let initiatorTimestamp = Date(timeInterval: 2 * 24 * 60 * 60, since: Date())
        let responderTimestamp = Date(timeInterval: 1 * 24 * 60 * 60, since: Date())

        let swap = Swap(
                id: id, state: Swap.State.responded, initiator: false,
                initiatorCoinCode: initiatorCoinCode, responderCoinCode: responderCoinCode,
                rate: rate, amount: amount, secretHash: secretHash, secret: nil,
                initiatorTimestamp: Int(initiatorTimestamp.timeIntervalSince1970), responderTimestamp: Int(responderTimestamp.timeIntervalSince1970),
                refundPKId: refundPKH.id, redeemPKId: redeemPKH.id,
                initiatorRefundPKH: initiatorRefundPKH, initiatorRedeemPKH: initiatorRedeemPKH,
                responderRefundPKH: refundPKH.keyHash, responderRedeemPKH: redeemPKH.keyHash
        )


        storage.add(swap: swap)
        return swap
    }

    func swap(fromResponseId id: String, responderRedeemPKH: Data, responderRefundPKH: Data, initiatorTimestamp: Int, responderTimestamp: Int) throws -> Swap {
        guard let swap = storage.getSwap(id: id) else {
            throw FactoryError.swapNotFound
        }

        swap.state = Swap.State.responded
        swap.responderRedeemPKH = responderRedeemPKH
        swap.responderRefundPKH = responderRefundPKH
        swap.initiatorTimestamp = initiatorTimestamp
        swap.responderTimestamp = responderTimestamp

        storage.update(swap: swap)
        return swap
    }

    func swapInitiator(swap: Swap) throws -> ISwapInitiator {
        var initiatorBlockchain = try blockchain(from: swap.initiatorCoinCode)
        var responderBlockchain = try blockchain(from: swap.responderCoinCode)

        let swapInitiator = SwapInitiator(initiatorBlockchain: initiatorBlockchain, responderBlockchain: responderBlockchain, storage: storage, swap: swap)
        initiatorBlockchain.delegate = swapInitiator
        responderBlockchain.delegate = swapInitiator

        return swapInitiator
    }

    func swapResponder(swap: Swap) throws -> ISwapResponder {
        var initiatorBlockchain = try blockchain(from: swap.initiatorCoinCode)
        var responderBlockchain = try blockchain(from: swap.responderCoinCode)

        let swapResponder = SwapResponder(initiatorBlockchain: initiatorBlockchain, responderBlockchain: responderBlockchain, storage: storage, swap: swap)
        initiatorBlockchain.delegate = swapResponder
        responderBlockchain.delegate = swapResponder

        return swapResponder
    }

}
