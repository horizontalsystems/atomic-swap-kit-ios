import Foundation

public struct PublicKey {
    public let id: String
    public let keyHash: Data
    
    public init(id: String, keyHash: Data) {
        self.id = id
        self.keyHash = keyHash
    }
    
}
