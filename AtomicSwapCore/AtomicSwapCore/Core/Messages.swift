import Foundation

public struct RequestMessage {
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
}


public struct ResponseMessage {
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
}
