import Foundation

protocol ISwapStorage {
    func swapsInProgress() -> [Swap]
    func add(swap: Swap)
    func getSwap(id orderId: String) -> Swap?
    func update(swap: Swap)
}

protocol ISwapFactory {
    func register(blockchainCreator: ISwapBlockchainCreator, forCoin coin: String)
    func unregister(coin: String)
    func blockchain(from coinCode: String) throws -> ISwapBlockchain
    func swap(initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double) throws -> Swap
    func swap(fromRequestId: String, initiatorCoinCode: String, responderCoinCode: String, rate: Double, amount: Double, initiatorRefundPKH: Data, initiatorRedeemPKH: Data, secretHash: Data) throws -> Swap
    func swap(fromResponseId: String, responderRedeemPKH: Data, responderRefundPKH: Data, initiatorTimestamp: Int, responderTimestamp: Int) throws -> Swap
    func swapInitiator(swap: Swap) throws -> ISwapInitiator
    func swapResponder(swap: Swap) throws -> ISwapResponder
}

protocol ISwapInitiator {
    var swap: Swap { get }
    func proceedNext() throws
    func start() throws
}

protocol ISwapResponder {
    var swap: Swap { get }
    func proceedNext() throws
    func start() throws
}

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
