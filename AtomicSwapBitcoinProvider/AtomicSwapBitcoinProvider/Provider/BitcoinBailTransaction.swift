import Foundation
import AtomicSwapCore

public class BitcoinBailTransaction : IBailTransaction {
    
    let transactionHash: Data
    let outputIndex: Int
    let amount: Int
    let lockingScript: Data

    public init(transactionHash: Data, outputIndex: Int, amount: Int, lockingScript: Data) {
        self.transactionHash = transactionHash
        self.outputIndex = outputIndex
        self.amount = amount
        self.lockingScript = lockingScript
    }
    
}
