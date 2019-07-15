import GRDB

public class Swap: Record {
    public enum State: Int, DatabaseValueConvertible {
        case requested
        case responded
        case initiatorBailed
        case responderBailed
        case initiatorRedeemed
        case responderRedeemed
    }

    let id: String
    var state: State
    let initiator: Bool
    let initiatorCoinCode: String
    let responderCoinCode: String
    let rate: Double
    let amount: Double
    let secretHash: Data
    var secret: Data?
    var initiatorTimestamp: Int?
    var responderTimestamp: Int?
    var refundPKId: String?
    var redeemPKId: String?
    let initiatorRefundPKH: Data
    let initiatorRedeemPKH: Data
    var responderRefundPKH: Data?
    var responderRedeemPKH: Data?
    var initiatorBailTransaction: Data?
    var responderBailTransaction: Data?

    public init(id: String, state: State, initiator: Bool, initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double, secretHash: Data,
                secret: Data?, initiatorTimestamp: Int?, responderTimestamp: Int?,
                refundPKId: String?, redeemPKId: String?, initiatorRefundPKH: Data, initiatorRedeemPKH: Data,
                responderRefundPKH: Data?, responderRedeemPKH: Data?) {
        self.id = id
        self.state = state
        self.initiator = initiator
        self.initiatorCoinCode = initiatorCoinCode
        self.responderCoinCode = responderCoinCode
        self.rate = rate
        self.amount = amount
        self.secretHash = secretHash
        self.secret = secret
        self.initiatorTimestamp = initiatorTimestamp
        self.responderTimestamp = responderTimestamp
        self.refundPKId = refundPKId
        self.redeemPKId = redeemPKId
        self.initiatorRefundPKH = initiatorRefundPKH
        self.initiatorRedeemPKH = initiatorRedeemPKH
        self.responderRefundPKH = responderRefundPKH
        self.responderRedeemPKH = responderRedeemPKH

        super.init()
    }

    override open class var databaseTableName: String {
        return "swaps"
    }

    public enum Columns: String, ColumnExpression, CaseIterable {
        case id
        case state
        case initiator
        case initiatorCoinCode
        case responderCoinCode
        case rate
        case amount
        case secretHash
        case secret
        case initiatorTimestamp
        case responderTimestamp
        case refundPKId
        case redeemPKId
        case initiatorRefundPKH
        case initiatorRedeemPKH
        case responderRefundPKH
        case responderRedeemPKH
        case initiatorBailTransaction
        case responderBailTransaction
    }

    required init(row: Row) {
        id = row[Columns.id]
        state = row[Columns.state]
        initiator = row[Columns.initiator]
        initiatorCoinCode = row[Columns.initiatorCoinCode]
        responderCoinCode = row[Columns.responderCoinCode]
        rate = row[Columns.rate]
        amount = row[Columns.amount]
        secretHash = row[Columns.secretHash]
        secret = row[Columns.secret]
        initiatorTimestamp = row[Columns.initiatorTimestamp]
        responderTimestamp = row[Columns.responderTimestamp]
        refundPKId = row[Columns.refundPKId]
        redeemPKId = row[Columns.redeemPKId]
        initiatorRefundPKH = row[Columns.initiatorRefundPKH]
        initiatorRedeemPKH = row[Columns.initiatorRedeemPKH]
        responderRefundPKH = row[Columns.responderRefundPKH]
        responderRedeemPKH = row[Columns.responderRedeemPKH]
        initiatorBailTransaction = row[Columns.initiatorBailTransaction]
        responderBailTransaction = row[Columns.responderBailTransaction]

        super.init(row: row)
    }

    override open func encode(to container: inout PersistenceContainer) {
        container[Columns.id] = id
        container[Columns.state] = state
        container[Columns.initiator] = initiator
        container[Columns.initiatorCoinCode] = initiatorCoinCode
        container[Columns.responderCoinCode] = responderCoinCode
        container[Columns.rate] = rate
        container[Columns.amount] = amount
        container[Columns.secretHash] = secretHash
        container[Columns.secret] = secret
        container[Columns.initiatorTimestamp] = initiatorTimestamp
        container[Columns.responderTimestamp] = responderTimestamp
        container[Columns.refundPKId] = refundPKId
        container[Columns.redeemPKId] = redeemPKId
        container[Columns.initiatorRefundPKH] = initiatorRefundPKH
        container[Columns.initiatorRedeemPKH] = initiatorRedeemPKH
        container[Columns.responderRefundPKH] = responderRefundPKH
        container[Columns.responderRedeemPKH] = responderRedeemPKH
        container[Columns.initiatorBailTransaction] = initiatorBailTransaction
        container[Columns.responderBailTransaction] = responderBailTransaction
    }

}
