import HSCryptoKit
import BitcoinCore
import AtomicSwapCore

public class BitcoinSwapBlockchain: ISwapBlockchain {
    enum BitcoinKitSwapBlockchainError: Error {
        case noKitFound
        case transactionNotSent
        case transactionFromOtherBlockchain
    }

    static let satoshiPerBitcoin = 100_000_000.0

    public let coinCode: String
    let scriptBuilder: SwapScriptBuilder

    weak var kit: AbstractKit?
    public weak var delegate: ISwapBlockchainDelegate?

    init(coinCode: String, kit: AbstractKit, scriptBuilder: SwapScriptBuilder) {
        self.coinCode = coinCode
        self.kit = kit
        self.scriptBuilder = scriptBuilder
    }

    public var synced: Bool {
        return (kit?.syncState ?? .notSynced) == .synced
    }

    public func changePublicKey() throws -> AtomicSwapCore.PublicKey {
        guard let kit = self.kit else {
            throw BitcoinKitSwapBlockchainError.noKitFound
        }

        let bitcoinCorePK = try kit.changePublicKey()
        return AtomicSwapCore.PublicKey(id: bitcoinCorePK.path, keyHash: bitcoinCorePK.keyHash)
    }

    public func receivePublicKey() throws -> AtomicSwapCore.PublicKey {
        guard let kit = self.kit else {
            throw BitcoinKitSwapBlockchainError.noKitFound
        }

        let bitcoinCorePK = try kit.receivePublicKey()

        return AtomicSwapCore.PublicKey(id: bitcoinCorePK.path, keyHash: bitcoinCorePK.keyHash)
    }

    public func watchBailTransaction(withRedeemKeyHash redeemKeyHash: Data, refundKeyHash: Data, secretHash: Data, timestamp: Int) {
        let redeemScript = scriptBuilder.redeemScript(redeemKeyHash: redeemKeyHash, refundKeyHash: refundKeyHash, secretHash: secretHash, timestamp: timestamp)
        let scriptHash = CryptoKit.sha256ripemd160(redeemScript)

        kit?.watch(transaction: BitcoinCore.TransactionFilter.p2shOutput(scriptHash: scriptHash), delegate: self)
    }

    public func sendBailTransaction(withRedeemKeyHash redeemKeyHash: Data, refundKeyHash: Data, secretHash: Data, timestamp: Int, amount: Double) throws -> IBailTransaction {
        let redeemScript = scriptBuilder.redeemScript(redeemKeyHash: redeemKeyHash, refundKeyHash: refundKeyHash, secretHash: secretHash, timestamp: timestamp)
        let scriptHash = CryptoKit.sha256ripemd160(redeemScript)

        guard let transaction = try kit?.send(to: scriptHash, scriptType: .p2sh, value: Int(amount * BitcoinSwapBlockchain.satoshiPerBitcoin), feeRate: 42) else {
            throw BitcoinKitSwapBlockchainError.transactionNotSent
        }

        for output in transaction.outputs {
            if let keyHash = output.keyHash, output.scriptType == .p2sh && keyHash == scriptHash {
                return BitcoinBailTransaction(transactionHash: transaction.header.dataHash, outputIndex: output.index, amount: output.value, lockingScript: output.lockingScript)
            }
        }

        throw BitcoinKitSwapBlockchainError.transactionNotSent
    }

    public func watchRedeemTransaction(fromTransaction: IBailTransaction) throws {
        guard let transaction = fromTransaction as? BitcoinBailTransaction else {
            throw BitcoinKitSwapBlockchainError.transactionFromOtherBlockchain
        }

        kit?.watch(transaction: BitcoinCore.TransactionFilter.outpoint(transactionHash: transaction.transactionHash, outputIndex: transaction.outputIndex), delegate: self)
    }

    public func sendRedeemTransaction(from bailTransaction: IBailTransaction, withRedeemKeyHash redeemKeyHash: Data, redeemPKId: String, refundKeyHash: Data, secret: Data, secretHash: Data, timestamp: Int) throws {
        guard let transaction = bailTransaction as? BitcoinBailTransaction else {
            throw BitcoinKitSwapBlockchainError.transactionFromOtherBlockchain
        }

        let redeemScript = scriptBuilder.redeemScript(redeemKeyHash: redeemKeyHash, refundKeyHash: refundKeyHash, secretHash: secretHash, timestamp: timestamp)
        let scriptHash = CryptoKit.sha256ripemd160(redeemScript)

        guard let kit = self.kit else {
            return
        }

        let publicKey = try kit.publicKey(byPath: redeemPKId)
        let output = Output(
                withValue: transaction.amount, index: transaction.outputIndex, lockingScript: transaction.lockingScript,
                transactionHash: transaction.transactionHash, type: .p2sh, redeemScript: redeemScript, keyHash: scriptHash, publicKey: publicKey
        )
        let unspentOutput = UnspentOutput(output: output, publicKey: publicKey, transaction: Transaction(version: 0, lockTime: 0, timestamp: nil))

        _ = try kit.redeem(from: unspentOutput, to: kit.receiveAddress(for: .p2pkh), feeRate: 43) { signature, publicKey in
            return OpCode.push(signature) + OpCode.push(publicKey) + OpCode.push(secret) + OpCode.push(1) + OpCode.push(redeemScript)
        }
    }

    public func bailTransaction(from data: Data) throws -> IBailTransaction {
        guard data.count > 48 else {
            throw BitcoinKitSwapBlockchainError.transactionFromOtherBlockchain
        }

        return BitcoinBailTransaction(
                transactionHash: data.subdata(in: 0..<32),
                outputIndex: Data(data.subdata(in: 32..<40)).to(type: Int.self),
                amount: Data(data.subdata(in: 40..<48)).to(type: Int.self),
                lockingScript: data.subdata(in: 48..<data.count)
        )
    }

    public func data(from transaction: IBailTransaction) throws -> Data {
        guard let bitcoinTransaction = transaction as? BitcoinBailTransaction else {
            throw BitcoinKitSwapBlockchainError.transactionFromOtherBlockchain
        }

        return bitcoinTransaction.transactionHash + Data(from: bitcoinTransaction.outputIndex) +
                Data(from: bitcoinTransaction.amount) + bitcoinTransaction.lockingScript
    }

}

extension BitcoinSwapBlockchain: IWatchedTransactionDelegate {

    public func transactionReceived(transaction: FullTransaction, outputIndex: Int) {
        let output = transaction.outputs[outputIndex]
        let bailTransaction = BitcoinBailTransaction(transactionHash: transaction.header.dataHash, outputIndex: output.index, amount: output.value, lockingScript: output.lockingScript)
        delegate?.onBailTransactionReceived(bailTransaction: bailTransaction)
    }

    public func transactionReceived(transaction: FullTransaction, inputIndex: Int) {
        let input = transaction.inputs[inputIndex]
        guard let secret = try? scriptBuilder.getSecret(from: input.signatureScript) else {
            return
        }

        let redeemTransaction = BitcoinRedeemTransaction(transactionHash: transaction.header.dataHash, secret: secret)
        delegate?.onRedeemTransactionReceived(redeemTransaction: redeemTransaction)
    }

}
