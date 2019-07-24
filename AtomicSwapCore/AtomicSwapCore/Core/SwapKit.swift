import Foundation

public class SwapKit {
    enum SwapError : Error {
        case couldNotGenerateSwap
        case swapNotFound
    }

    private let storage: ISwapStorage
    private let factory: ISwapFactory
    private let logger: Logger?

    private var initiators = [String: ISwapInitiator]()
    private var responders = [String: ISwapResponder]()

    init(storage: ISwapStorage, factory: ISwapFactory, logger: Logger? = nil) {
        self.storage = storage
        self.factory = factory
        self.logger = logger
    }

    public func proceedNext() throws {
        for (_, initiator) in initiators {
            try initiator.proceedNext()
        }

        for (_, responder) in responders {
            try responder.proceedNext()
        }
    }

    public func load() {
        for swap in storage.swapsInProgress() {
            if swap.initiator {
                do {
                    let initiator = try factory.swapInitiator(swap: swap)
                    initiators[swap.id] = initiator
                } catch {
                    logger?.error(error)
                }
            } else {
                do {
                    let responder = try factory.swapResponder(swap: swap)
                    responders[swap.id] = responder
                } catch {
                    logger?.error(error)
                }
            }
        }
    }

    public func register(blockchainCreator: ISwapBlockchainCreator, forCoin coin: String) {
        factory.register(blockchainCreator: blockchainCreator, forCoin: coin)
    }

    public func unregister(coin: String) {
        factory.unregister(coin: coin)
    }

    public func createSwapRequest(haveCoinCode: String, wantCoinCode: String, rate: Double, amount: Double) throws -> SwapRequest {
        let swap = try factory.swap(initiatorCoinCode: haveCoinCode, responderCoinCode: wantCoinCode, rate: rate, amount: amount)

        return SwapRequest(swap: swap)
    }

    public func createSwapResponse(from request: SwapRequest) throws -> SwapResponse {
        let swap = try factory.swap(
                fromRequestId: request.id, initiatorCoinCode: request.initiatorCoinCode, responderCoinCode: request.responderCoinCode,
                rate: request.rate, amount: request.amount,
                initiatorRefundPKH: request.initiatorRefundPKH, initiatorRedeemPKH: request.initiatorRedeemPKH,
                secretHash: request.secretHash
        )

        let swapResponder = try factory.swapResponder(swap: swap)
        try swapResponder.proceedNext()

        responders[swap.id] = swapResponder

        return SwapResponse(swap: swap)
    }

    public func initiateSwap(from response: SwapResponse) throws {
        let swap = try factory.swap(
                fromResponseId: response.id,
                responderRedeemPKH: response.responderRedeemPKH, responderRefundPKH: response.responderRefundPKH,
                initiatorTimestamp: response.initiatorTimestamp, responderTimestamp: response.responderTimestamp
        )

        let swapInitiator = try factory.swapInitiator(swap: swap)
        try swapInitiator.proceedNext()

        initiators[swap.id] = swapInitiator
    }

}

extension SwapKit {

    public static func instance(logger: Logger = Logger(minLogLevel: .error)) -> SwapKit {
        let storage = SwapStorage()
        let factory = SwapFactory(storage: storage)

        return SwapKit(storage: storage, factory: factory, logger: logger)
    }

}
