import Foundation

class RandomHelper {
    static let shared = RandomHelper()

    var randomInt: Int {
        return Int.random(in: 0..<Int.max)
    }

    func randomBytes(length: Range<Int>) -> Data {
        return randomBytes(length: Int.random(in: length))
    }

    func randomBytes(length: Int) -> Data {
        var bytes = Data(count: length)
        let _ = bytes.withUnsafeMutableBytes { mutableBytes -> Int32 in
            SecRandomCopyBytes(kSecRandomDefault, length, mutableBytes.baseAddress!.assumingMemoryBound(to: UInt8.self))
        }

        return bytes
    }

}
