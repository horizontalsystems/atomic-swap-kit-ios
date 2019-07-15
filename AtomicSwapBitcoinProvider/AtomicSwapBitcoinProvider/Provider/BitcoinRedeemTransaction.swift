import Foundation
import AtomicSwapCore

public class BitcoinRedeemTransaction : IRedeemTransaction {

    public let secret: Data
    public let transactionHash: Data

    public init(transactionHash: Data, secret: Data) {
        self.transactionHash = transactionHash
        self.secret = secret
    }
    
}
