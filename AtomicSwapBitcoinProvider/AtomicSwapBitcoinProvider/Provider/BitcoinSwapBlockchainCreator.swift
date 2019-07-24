import BitcoinCore
import AtomicSwapCore

public class BitcoinSwapBlockchainCreator : ISwapBlockchainCreator {

    weak var kit: AbstractKit?
    private let scriptBuilder = SwapScriptBuilder()

    public init(kit: AbstractKit) {
        self.kit = kit
    }

    public func create() throws -> ISwapBlockchain {
        guard let kit = self.kit else {
            throw BitcoinSwapBlockchain.BitcoinKitSwapBlockchainError.noKitFound
        }

        return BitcoinSwapBlockchain(kit: kit, scriptBuilder: scriptBuilder)
    }

}
