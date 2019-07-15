import Foundation
import BitcoinCore

public class SwapScriptBuilder {
    enum SwapScriptBuilderError: Error {
        case wrongSwapSignatureScript
        case wrongSecret
    }
    
    public init() {}

    func redeemScript(redeemKeyHash: Data, refundKeyHash: Data, secretHash: Data, timestamp: Int) -> Data {
        var script = Data()

        script += [OpCode._if]
        script += [OpCode.size] + OpCode.push(Data([0x20])) + [OpCode.equalVerify]
        script += [OpCode.sha256] + OpCode.push(secretHash) + [OpCode.equalVerify]
        script += [OpCode.dup, OpCode.hash160] + OpCode.push(redeemKeyHash)
        script += [OpCode._else]
        script += OpCode.push(Data(from: timestamp)) + [OpCode.checkLockTimeVerify]
        script += [OpCode.drop, OpCode.dup, OpCode.hash160] + OpCode.push(refundKeyHash)
        script += [OpCode.endIf]
        script += [OpCode.equalVerify, OpCode.checkSig]

        return script
    }

    func getSecret(from script: Data) throws -> Data {
        let scriptData = SignatureScriptSerializer.deserialize(data: script)

        guard scriptData.count == 5 else {
            throw SwapScriptBuilderError.wrongSwapSignatureScript
        }

        let secret = scriptData[2]

        guard secret.count == 32 else {
            throw SwapScriptBuilderError.wrongSecret
        }

        return secret
    }

}
