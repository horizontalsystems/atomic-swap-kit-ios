import UIKit
import RxSwift
import BitcoinCore
import AtomicSwapCore
import RSSelectionMenu

class SwapController: UIViewController {
    private let disposeBag = DisposeBag()
    
    @IBOutlet weak var haveCoinLabel: UILabel?
    @IBOutlet weak var wantCoinLabel: UILabel?
    @IBOutlet weak var rateTextField: UITextField?
    @IBOutlet weak var valueTextField: UITextField?
    @IBOutlet weak var requestTextField: UITextField?
    @IBOutlet weak var responseTextField: UITextField?
    @IBOutlet weak var generatedMessage: UITextView?

    private var codec = PlainSwapCodec()
    private var haveCoinMenu: RSSelectionMenu<String>?
    private var wantCoinMenu: RSSelectionMenu<String>?
    private var haveCoinAdapter: BaseAdapter?
    private var wantCoinAdapter: BaseAdapter?

    private var adapters: [BaseAdapter] {
        return Manager.shared.adapters
    }

    private var swapKit: SwapKit {
        return Manager.shared.swapKit
    }
    
    private var coinsDataSource: DataSource<String> {
        return adapters.map { $0.coinCode }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Manager.shared.adapterSignal
            .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                self?.updateAdaptersMenu()
            })
            .disposed(by: disposeBag)
        
        updateAdaptersMenu()
    }
    
    
    private func updateAdaptersMenu() {
        haveCoinMenu = RSSelectionMenu(dataSource: coinsDataSource) { (cell, name, indexPath) in
            cell.textLabel?.text = name
        }
        
        var selectedItems = [String]()
        if let haveCoinAdapter = self.haveCoinAdapter {
            selectedItems.append(haveCoinAdapter.coinCode)
        }
        haveCoinMenu?.setSelectedItems(items: selectedItems) { name, index, selected, selectedItems in
            self.haveCoinAdapter = self.adapters.first { $0.coinCode == name }
            self.haveCoinLabel?.text = "Have: \(self.haveCoinAdapter?.coinCode ?? "?")"
        }
        
        wantCoinMenu = RSSelectionMenu(dataSource: coinsDataSource) { (cell, name, indexPath) in
            cell.textLabel?.text = name
        }
        
        selectedItems = [String]()
        if let wantCoinAdapter = self.wantCoinAdapter {
            selectedItems.append(wantCoinAdapter.coinCode)
        }
        wantCoinMenu?.setSelectedItems(items: selectedItems) { name, index, selected, selectedItems in
            self.wantCoinAdapter = self.adapters.first { $0.coinCode == name }
            self.wantCoinLabel?.text = "Want: \(self.wantCoinAdapter?.coinCode ?? "?")"
        }
    }
    
    @IBAction func changeHaveCoin() {
        haveCoinMenu?.show(from: self)
    }
    
    @IBAction func changeWantCoin() {
        wantCoinMenu?.show(from: self)
    }

    @IBAction func generateRequest() {
        guard let rateString = rateTextField?.text, let rate = Decimal(string: rateString) else {
            show(error: "Invalid rate")
            return
        }

        guard let valueString = valueTextField?.text, let value = Decimal(string: valueString) else {
            show(error: "Invalid value")
            return
        }

        guard let haveCoinAdapter = haveCoinAdapter, let wantCoinAdapter = wantCoinAdapter, haveCoinAdapter.coinCode != wantCoinAdapter.coinCode else {
            show(error: "Invalid coins selected")
            return
        }

        let requestStr: String
        do {
            let request = try swapKit.createSwapRequest(haveCoinCode: haveCoinAdapter.coinCode, wantCoinCode: wantCoinAdapter.coinCode, rate: Double(truncating: rate as NSNumber), amount: Double(truncating: value as NSNumber))
            requestStr = codec.getString(from: request)
        } catch {
            show(error: error.localizedDescription)
            return
        }

        generatedMessage?.text = requestStr
    }

    @IBAction func acceptRequest() {
        guard let requestStr = requestTextField?.text else {
            show(error: "Invalid request")
            return
        }

        let responseStr: String
        do {
            let request = try codec.getRequest(from: requestStr)
            let response = try swapKit.createSwapResponse(from: request)
            responseStr = codec.getString(from: response)
        } catch {
            show(error: error.localizedDescription)
            return
        }

        generatedMessage?.text = responseStr
    }
    
    @IBAction func initiateSwap() {
        guard let responseStr = responseTextField?.text else {
            show(error: "Invalid response")
            return
        }

        do {
            let response = try codec.getResponse(from: responseStr)
            try swapKit.initiateSwap(from: response)
        } catch {
            show(error: error.localizedDescription)
            return
        }
    }

    @IBAction func copyMessage() {
        UIPasteboard.general.string = generatedMessage?.text
    }
    
    private func show(error: String) {
        let alert = UIAlertController(title: "Send Error", message: error, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
    
    private func showSuccess(address: String, amount: Decimal) {
        let alert = UIAlertController(title: "Success", message: "\(amount.description) sent to \(address)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }

}

