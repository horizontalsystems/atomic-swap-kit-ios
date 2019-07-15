import BitcoinCore
import AtomicSwapCore

class PlainSwapCodec {
    enum PlainSwapCodecError : Error {
        case wrongRequest
        case wrongResponse
    }

    func getString(from message: RequestMessage) -> String {
        return "\(message.id)|\(message.initiatorCoinCode)|\(message.responderCoinCode)|\(message.rate)|\(message.amount)|\(message.secretHash.hex)|\(message.initiatorRefundPKH.hex)|\(message.initiatorRedeemPKH.hex)"
    }

    func getRequest(from str: String) throws -> RequestMessage {
        let parts = str.split(separator: "|").map { String($0) }

        guard parts.count == 8 else {
            throw PlainSwapCodecError.wrongRequest
        }

        let id = parts[0]
        let initiatorCoinCode = parts[1]
        let responderCoinCode = parts[2]

        guard let rate = Double(parts[3]), let amount = Double(parts[4]),
              let secretHash = Data(hex: parts[5]),
              let initiatorRefundPKH = Data(hex: parts[6]), let initiatorRedeemPKH = Data(hex: parts[7]) else {
            throw PlainSwapCodecError.wrongRequest
        }

        return RequestMessage(
                id: id, initiatorCoinCode: initiatorCoinCode, responderCoinCode: responderCoinCode,
                rate: rate, amount: amount, secretHash: secretHash,
                initiatorRefundPKH: initiatorRefundPKH, initiatorRedeemPKH: initiatorRedeemPKH)
    }

    func getString(from response: ResponseMessage) -> String {
        return "\(response.id)|\(response.initiatorTimestamp)|\(response.responderTimestamp)|\(response.responderRefundPKH.hex)|\(response.responderRedeemPKH.hex)"
    }

    func getResponse(from str: String) throws -> ResponseMessage {
        let parts = str.split(separator: "|").map { String($0) }

        guard parts.count == 5 else {
            throw PlainSwapCodecError.wrongResponse
        }

        let id = parts[0]

        guard let initiatorTimestamp = Int(parts[1]), let responderTimestamp = Int(parts[2]),
              let responderRefundPKH = Data(hex: parts[3]), let responderRedeemPKH = Data(hex: parts[4]) else {
            throw PlainSwapCodecError.wrongResponse
        }

        return ResponseMessage(
                id: id, initiatorTimestamp: initiatorTimestamp, responderTimestamp: responderTimestamp,
                responderRefundPKH: responderRefundPKH, responderRedeemPKH: responderRedeemPKH
        )
    }

}
