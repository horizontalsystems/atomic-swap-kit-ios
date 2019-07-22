import Foundation

public struct SwapRequest {
    public let id: String
    public let initiatorCoinCode: String
    public let responderCoinCode: String
    public let rate: Double
    public let amount: Double
    public let secretHash: Data
    public let initiatorRefundPKH: Data
    public let initiatorRedeemPKH: Data
    
    public init(id: String, initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double, secretHash: Data, initiatorRefundPKH: Data, initiatorRedeemPKH: Data) {
        self.id = id
        self.initiatorCoinCode = initiatorCoinCode
        self.responderCoinCode = responderCoinCode
        self.rate = rate
        self.amount = amount
        self.secretHash = secretHash
        self.initiatorRefundPKH = initiatorRefundPKH
        self.initiatorRedeemPKH = initiatorRedeemPKH
    }

    public init(swap: Swap) {
        id = swap.id
        initiatorCoinCode = swap.initiatorCoinCode
        responderCoinCode = swap.responderCoinCode
        rate = swap.rate
        amount = swap.amount
        secretHash = swap.secretHash
        initiatorRefundPKH = swap.initiatorRefundPKH
        initiatorRedeemPKH = swap.initiatorRedeemPKH
    }
}


public struct SwapResponse {
    public let id: String
    public let initiatorTimestamp: Int
    public let responderTimestamp: Int
    public let responderRefundPKH: Data
    public let responderRedeemPKH: Data
    
    public init(id: String, initiatorTimestamp: Int, responderTimestamp: Int, responderRefundPKH: Data, responderRedeemPKH: Data) {
        self.id = id
        self.initiatorTimestamp = initiatorTimestamp
        self.responderTimestamp = responderTimestamp
        self.responderRefundPKH = responderRefundPKH
        self.responderRedeemPKH = responderRedeemPKH
    }

    public init(swap: Swap) {
        id = swap.id
        initiatorTimestamp = swap.initiatorTimestamp!
        responderTimestamp = swap.responderTimestamp!
        responderRefundPKH = swap.responderRefundPKH!
        responderRedeemPKH = swap.responderRedeemPKH!
    }
}
