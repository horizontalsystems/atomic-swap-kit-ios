platform :ios, '11.0'
use_frameworks!

inhibit_all_warnings!

workspace 'AtomicSwapKit'

project 'Demo/Demo'
project 'AtomicSwapCore/AtomicSwapCore'
project 'AtomicSwapBitcoinProvider/AtomicSwapBitcoinProvider'



target :AtomicSwapCore do
  project 'AtomicSwapCore/AtomicSwapCore'

  pod 'HSCryptoKit', '~> 1.4'
  pod 'GRDB.swift', '~> 4.0'
end

target :AtomicSwapBitcoinProvider do
  project 'AtomicSwapBitcoinProvider/AtomicSwapBitcoinProvider'

  pod 'HSCryptoKit', '~> 1.4'
  pod 'BitcoinCore.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  pod 'BitcoinKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  pod 'BitcoinCashKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
end

target :Demo do
  project 'Demo/Demo'

  pod 'RSSelectionMenu'
  pod 'HSHDWalletKit', '~> 1'
  pod 'RxSwift', '~> 5.0'

  pod 'BitcoinCore.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  pod 'BitcoinKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  pod 'BitcoinCashKit.swift', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
end


target :AtomicSwapCoreTests do
  project 'AtomicSwapCore/AtomicSwapCore'

  pod 'Quick'
  pod 'Nimble'
  pod 'Cuckoo'
end
