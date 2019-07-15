import Foundation

public protocol ISwapBlockchain {
    var delegate: ISwapBlockchainDelegate? { get set }
    var coinCode: String { get }
    var synced: Bool { get }
    func changePublicKey() throws -> PublicKey
    func receivePublicKey() throws -> PublicKey
    func watchBailTransaction(withRedeemKeyHash: Data, refundKeyHash: Data, secretHash: Data, timestamp: Int)
    func sendBailTransaction(withRedeemKeyHash redeemKeyHash: Data, refundKeyHash: Data, secretHash: Data, timestamp: Int, amount: Double) throws -> IBailTransaction
    func sendRedeemTransaction(from: IBailTransaction, withRedeemKeyHash: Data, redeemPKId: String, refundKeyHash: Data, secret: Data, secretHash: Data, timestamp: Int) throws
    func watchRedeemTransaction(fromTransaction: IBailTransaction) throws
    func bailTransaction(from: Data) throws -> IBailTransaction
    func data(from: IBailTransaction) throws -> Data
}

public protocol ISwapBlockchainDelegate: class {
    func onBailTransactionReceived(bailTransaction: IBailTransaction)
    func onRedeemTransactionReceived(redeemTransaction: IRedeemTransaction)
}

public protocol ISwapBlockchainCreator {
    func create() throws -> ISwapBlockchain
}

public protocol IBailTransaction {
}

public protocol IRedeemTransaction {
    var secret: Data { get }
}
