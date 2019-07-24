## Overview

This is a swift library that allows Atomic Swap, decentralized crypto currency exchange, between 2 parties. The implementation is based on Hash Time Locked Contracts.


## Usage

### Initialization

The primary class to use is `SwapKit`.

```swift
import BitcoinKit
import BitcoinCashKit
import AtomicSwapKit

let swapKit = SwapKit.instance()

swapKit.register(blockchainCreator: BitcoinSwapBlockchainCreator(kit: bitcoinAdapter.bitcoinKit), forCoin: "BTC")
swapKit.register(blockchainCreator: BitcoinSwapBlockchainCreator(kit: bitcoinCashAdapter.bitcoinCashKit), forCoin: "BCH")
swapKit.load()

```

The supported coins should be registered to `SwapKit`. The `load` method resumes atomic swaps previously in progress.

### Exchanging crypto-curencies

There are 2 sides that take part in the process: Initiator and Responder. The process consists of the following steps:  

#### Request for a swap

Initiator creates swap request:

```swift
let swapRequest = try swapKit.createSwapRequest(haveCoinCode: "BTC", wantCoinCode: "BCH", rate: 0.2, amount: 0.5)
```

#### Response to a swap

Responder creates response for this request:   

```swift
let swapResponse = swapKit.createSwapResponse(from: swapRequest)
```

Creating response also starts the swap process in the Responder side.

#### Initiate swap

Initiator takes response and starts the swap

```swift
swapKit.initiateSwap(from: swapResponse)
```

### Initiator and Responder Communication

The Swap Request and Swap Response are the simple data objects. They can be easily serialized into/parsed from strings and interchanged via standard apps, like messenger or email.

## Prerequisites

* Xcode 10.0+
* Swift 5+
* iOS 11+

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

> CocoaPods 1.5.0+ is required to build BitcoinKit.

To integrate BitcoinKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '11.0'
use_frameworks!

target '<Your Target Name>' do
  pod 'AtomicSwapCore.swift'
  pod 'AtomicSwapBitcoinProvider'
end
```

Then, run the following command:
```bash
$ pod install
```


## Example Project

All features of the library are used in example project. It can be referred as a starting point for usage of the library.

* [Example Project](https://github.com/horizontalsystems/atomic-swap-kit-ios/tree/master/Demo)

## Dependencies

* [HSHDWalletKit](https://github.com/horizontalsystems/hd-wallet-kit-ios) - HD Wallet related features, mnemonic phrase geneartion.
* [HSCryptoKit](https://github.com/horizontalsystems/crypto-kit-ios) - Crypto functions required for working with blockchain.

## License

The `AtomicSwapKit-iOS` toolkit is open source and available under the terms of the [MIT License](https://github.com/horizontalsystems/atomic-swap-kit-ios/blob/master/LICENSE).