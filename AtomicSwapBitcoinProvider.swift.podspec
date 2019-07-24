Pod::Spec.new do |spec|
  spec.name = 'AtomicSwapBitcoinProvider.swift'
  spec.module_name = "AtomicSwapBitcoinProvider"
  spec.version = '0.0.1'
  spec.summary = 'Bitcoin provider for AtomicSwapCore library'
  spec.description = <<-DESC
                       AtomicSwapBitcoinProvider implements Bitcoin provider for AtomicSwapCore library. 
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/atomic-swap-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/atomic-swap-kit-ios.git', tag: "#{spec.version}" }
  spec.source_files = 'AtomicSwapBitcoinProvider/AtomicSwapBitcoinProvider/**/*.{h,m,swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5'

  spec.dependency 'HSCryptoKit', '~> 1.4'
  spec.dependency 'BitcoinCore.swift', '~> 0.7.0', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  spec.dependency 'BitcoinKit.swift', '~> 0.7.0', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  spec.dependency 'BitcoinCashKit.swift', '~> 0.7.0', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
  spec.dependency 'DashKit.swift', '~> 0.7.0', git: 'https://github.com/horizontalsystems/bitcoin-kit-ios/'
end