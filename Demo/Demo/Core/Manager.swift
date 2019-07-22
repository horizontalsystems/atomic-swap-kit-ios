import RxSwift
import BitcoinCore
import AtomicSwapCore
import AtomicSwapBitcoinProvider

class Manager {
    static let shared = Manager()
    private static let syncModes: [BitcoinCore.SyncMode] = [.full, .api, .newWallet]

    private let keyWords = "mnemonic_words"
    private let syncModeKey = "syncMode"

    let adapterSignal = Signal()
    var adapters = [BaseAdapter]()
    let disposeBag = DisposeBag()
    let swapKit = SwapKit.instance()
    var syncedStateFired: Bool = false

    init() {
        if let words = savedWords, let syncModeIndex = savedSyncModeIndex {
            DispatchQueue.global(qos: .userInitiated).async {
                self.initAdapters(words: words, syncMode: Manager.syncModes[syncModeIndex])
            }
        }
    }

    func login(words: [String], syncModeIndex: Int) {
        save(words: words)
        save(syncModeIndex: syncModeIndex)
        clearKits()

        DispatchQueue.global(qos: .userInitiated).async {
            self.initAdapters(words: words, syncMode: Manager.syncModes[syncModeIndex])
        }
    }

    func logout() {
        for adapter in adapters {
            swapKit.unregister(coin: adapter.coinCode)
        }

        clearUserDefaults()
        adapters = []
    }

    private func initAdapters(words: [String], syncMode: BitcoinCore.SyncMode) {
        let configuration = Configuration.shared
        let bitcoinAdapter = BitcoinAdapter(words: words, testMode: configuration.testNet, syncMode: syncMode)
        let bitcoinCashAdapter = BitcoinCashAdapter(words: words, testMode: configuration.testNet, syncMode: .newWallet)
//        let dashAdapter = DashAdapter(words: words, testMode: configuration.testNet, syncMode: syncMode)

        adapters = [
            bitcoinAdapter,
            bitcoinCashAdapter,
//            dashAdapter,
        ]

        let scriptBuilder = SwapScriptBuilder()
        swapKit.register(blockchainCreator: BitcoinSwapBlockchainCreator(coinCode: bitcoinAdapter.coinCode, kit: bitcoinAdapter.bitcoinKit, scriptBuilder: scriptBuilder), forCoin: bitcoinAdapter.coinCode)
        swapKit.register(blockchainCreator: BitcoinSwapBlockchainCreator(coinCode: bitcoinCashAdapter.coinCode, kit: bitcoinCashAdapter.bitcoinCashKit, scriptBuilder: scriptBuilder), forCoin: bitcoinCashAdapter.coinCode)
        swapKit.load()

        bitcoinAdapter.syncStateObservable.subscribe(
                    onNext: { [weak self] in
                        self?.fireSyncedState()
                    }
            )
            .disposed(by: disposeBag)

        bitcoinCashAdapter.syncStateObservable.subscribe(
                    onNext: { [weak self] in
                        self?.fireSyncedState()
                    }
            )
            .disposed(by: disposeBag)


        adapterSignal.notify()
    }

    var savedWords: [String]? {
        if let wordsString = UserDefaults.standard.value(forKey: keyWords) as? String {
            return wordsString.split(separator: " ").map(String.init)
        }
        return nil
    }

    var savedSyncModeIndex: Int? {
        if let syncModeIndex = UserDefaults.standard.value(forKey: syncModeKey) as? Int {
            return syncModeIndex
        }
        return nil
    }

    private func fireSyncedState() {
        guard !syncedStateFired else {
            return
        }

        syncedStateFired = true
        if adapters.first(where: { !($0.syncState == BitcoinCore.KitState.synced) }) == nil {
            try? swapKit.proceedNext()
        }
    }

    private func save(words: [String]) {
        UserDefaults.standard.set(words.joined(separator: " "), forKey: keyWords)
        UserDefaults.standard.synchronize()
    }

    private func save(syncModeIndex: Int) {
        UserDefaults.standard.set(syncModeIndex, forKey: syncModeKey)
        UserDefaults.standard.synchronize()
    }

    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: keyWords)
        UserDefaults.standard.removeObject(forKey: syncModeKey)
        UserDefaults.standard.synchronize()
    }

    private func clearKits() {
        BitcoinAdapter.clear()
        BitcoinCashAdapter.clear()
    }

}
