class SwapFactory {
    enum CreationError: Error {
        case blockchainNotSupported
    }

    let storage: SwapStorage
    var blockchainCreators = [String: ISwapBlockchainCreator]()

    init(storage: SwapStorage) {
        self.storage = storage
    }

    func register(blockchainCreator: ISwapBlockchainCreator, forCoin coin: String) {
        blockchainCreators[coin] = blockchainCreator
    }

    func unregister(coin: String) {
        blockchainCreators.removeValue(forKey: coin)
    }

    func blockchain(from coinCode: String) throws -> ISwapBlockchain {
        guard let creator = blockchainCreators[coinCode] else {
            throw CreationError.blockchainNotSupported
        }

        return try creator.create()
    }

    func swapInitiator(initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double) throws -> SwapInitiator {
        var initiatorBlockchain = try blockchain(from: initiatorCoinCode)
        var responderBlockchain = try blockchain(from: responderCoinCode)

        let swapInitiator = try SwapInitiator.generate(initiatorBlockchain: initiatorBlockchain, responderBlockchain: responderBlockchain, storage: storage, rate: rate, amount: amount)
        initiatorBlockchain.delegate = swapInitiator
        responderBlockchain.delegate = swapInitiator

        return swapInitiator
    }

    func swapInitiator(swap: Swap) throws -> SwapInitiator {
        var initiatorBlockchain = try blockchain(from: swap.initiatorCoinCode)
        var responderBlockchain = try blockchain(from: swap.responderCoinCode)

        let swapInitiator = SwapInitiator(initiatorBlockchain: initiatorBlockchain, responderBlockchain: responderBlockchain, storage: storage, swap: swap)
        initiatorBlockchain.delegate = swapInitiator
        responderBlockchain.delegate = swapInitiator

        return swapInitiator
    }

    func swapResponder(swap: Swap) throws -> SwapResponder {
        var initiatorBlockchain = try blockchain(from: swap.initiatorCoinCode)
        var responderBlockchain = try blockchain(from: swap.responderCoinCode)

        let swapResponder = SwapResponder(initiatorBlockchain: initiatorBlockchain, responderBlockchain: responderBlockchain, storage: storage, swap: swap)
        initiatorBlockchain.delegate = swapResponder
        responderBlockchain.delegate = swapResponder

        return swapResponder
    }

}
