import BitcoinCore
import AtomicSwapCore

public class BitcoinSwapBlockchainCreator : ISwapBlockchainCreator {

    weak var kit: AbstractKit?
    private let coinCode: String
    private let scriptBuilder: SwapScriptBuilder

    public init(coinCode: String, kit: AbstractKit, scriptBuilder: SwapScriptBuilder) {
        self.coinCode = coinCode
        self.kit = kit
        self.scriptBuilder = scriptBuilder
    }

    public func create() throws -> ISwapBlockchain {
        guard let kit = self.kit else {
            throw BitcoinSwapBlockchain.BitcoinKitSwapBlockchainError.noKitFound
        }

        return BitcoinSwapBlockchain(coinCode: coinCode, kit: kit, scriptBuilder: scriptBuilder)
    }

}
