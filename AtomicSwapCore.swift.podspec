Pod::Spec.new do |spec|
  spec.name = 'AtomicSwapCore.swift'
  spec.module_name = "AtomicSwapCore"
  spec.version = '0.0.1'
  spec.summary = 'Core library for atomic swaps between cryptocurencies in Swift'
  spec.description = <<-DESC
                       AtomicSwapCore implements atomic swaps between cryptocurrencies without third-party services or intermediaries. 
                       This is the core library. You need to have providers implemented in order to use this.
                       ```
                    DESC
  spec.homepage = 'https://github.com/horizontalsystems/atomic-swap-kit-ios'
  spec.license = { :type => 'Apache 2.0', :file => 'LICENSE' }
  spec.author = { 'Horizontal Systems' => 'hsdao@protonmail.ch' }
  spec.social_media_url = 'http://horizontalsystems.io/'

  spec.requires_arc = true
  spec.source = { git: 'https://github.com/horizontalsystems/atomic-swap-kit-ios.git', tag: "#{spec.version}" }
  spec.source_files = 'AtomicSwapCore/AtomicSwapCore/**/*.{h,m,swift}'
  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5'

  spec.dependency 'HSCryptoKit', '~> 1.4'
  spec.dependency 'GRDB.swift', '~> 4.0'
end