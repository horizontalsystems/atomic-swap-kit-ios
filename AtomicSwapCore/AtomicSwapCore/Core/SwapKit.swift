import Foundation
import HSCryptoKit.Private

public class SwapKit {
    public static let shared = SwapKit()

    enum SwapError : Error {
        case couldNotGenerateSwap
        case swapNotFound
    }

    private let storage: SwapStorage
    private let factory: SwapFactory

    private var initiators = [String: SwapInitiator]()
    private var responders = [String: SwapResponder]()

    init() {
        storage = SwapStorage()
        factory = SwapFactory(storage: storage)
    }

    public func triggerWatchers() throws {
        for swap in storage.allSwaps() {
            if swap.initiator {
                let initiator = try factory.swapInitiator(swap: swap)
                try initiator.triggerWatchers()
                initiators[initiator.swap.id] = initiator
            } else {
                let responder = try factory.swapResponder(swap: swap)
                try responder.triggerWatchers()
                responders[responder.swap.id] = responder
            }
        }
    }

    public func triggerTxSends() throws {
        for (_, initiator) in initiators {
            try initiator.triggerTxSends()
        }

        for (_, responder) in responders {
            try responder.triggerTxSends()
        }
    }

    public func register(blockchainCreator: ISwapBlockchainCreator, forCoin coin: String) {
        factory.register(blockchainCreator: blockchainCreator, forCoin: coin)
    }

    public func unregister(coin: String) {
        factory.unregister(coin: coin)
    }

    public func createSwapRequest(haveCoinCode: String, wantCoinCode: String, rate: Double, amount: Double) throws -> RequestMessage {
        let swapInitiator = try factory.swapInitiator(initiatorCoinCode: haveCoinCode, responderCoinCode: wantCoinCode, rate: rate, amount: amount)
        let swap = swapInitiator.swap

        initiators[swap.id] = swapInitiator

        return RequestMessage(
                id: swap.id, initiatorCoinCode: swap.initiatorCoinCode, responderCoinCode: swap.responderCoinCode,
                rate: swap.rate, amount: swap.amount, secretHash: swap.secretHash,
                initiatorRefundPKH: swap.initiatorRefundPKH, initiatorRedeemPKH: swap.initiatorRedeemPKH
        )
    }

    public func acceptSwapAndCreateResponse(request: RequestMessage) throws -> ResponseMessage {
        let requestedSwap = Swap(
                id: request.id, state: Swap.State.requested, initiator: false,
                initiatorCoinCode: request.initiatorCoinCode, responderCoinCode: request.responderCoinCode,
                rate: request.rate, amount: request.amount,
                secretHash: request.secretHash, secret: nil, initiatorTimestamp: nil, responderTimestamp: nil,
                refundPKId: nil, redeemPKId: nil,
                initiatorRefundPKH: request.initiatorRefundPKH, initiatorRedeemPKH: request.initiatorRedeemPKH,
                responderRefundPKH: nil, responderRedeemPKH: nil
        )

        let swapResponder = try factory.swapResponder(swap: requestedSwap)
        try swapResponder.respond()
        let swap = swapResponder.swap

        responders[swap.id] = swapResponder

        return ResponseMessage(
                id: swap.id, initiatorTimestamp: swap.initiatorTimestamp!, responderTimestamp: swap.responderTimestamp!,
                responderRefundPKH: swap.responderRefundPKH!, responderRedeemPKH: swap.responderRedeemPKH!
        )
    }

    public func initiateSwap(from response: ResponseMessage) throws {
        guard let swapInitiator = initiators[response.id] else {
            throw SwapError.swapNotFound
        }

        swapInitiator.swap.responderRedeemPKH = response.responderRedeemPKH
        swapInitiator.swap.responderRefundPKH = response.responderRefundPKH
        swapInitiator.swap.initiatorTimestamp = response.initiatorTimestamp
        swapInitiator.swap.responderTimestamp = response.responderTimestamp

        try swapInitiator.onResponderAgree()
    }

}
