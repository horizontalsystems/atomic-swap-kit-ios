import XCTest
import Cuckoo
import Nimble
import Quick
@testable import AtomicSwapCore

class SwapKitTests: QuickSpec {
    override func spec() {
        let mockStorage = MockISwapStorage()
        let mockFactory = MockISwapFactory()
        let mockInitiator = MockISwapInitiator()
        let mockResponder = MockISwapResponder()

        var initiatorSwap: Swap!
        var responderSwap: Swap!
        var kit: SwapKit!

        beforeEach {
            initiatorSwap = Swap(
                    id: "", state: .requested, initiator: true, initiatorCoinCode: "BTC", responderCoinCode: "BCH", 
                    rate: 0, amount: 0, secretHash: Data(), secret: nil,
                    initiatorTimestamp: nil, responderTimestamp: nil, refundPKId: nil, redeemPKId: nil,
                    initiatorRefundPKH: Data(), initiatorRedeemPKH: Data(), responderRefundPKH: nil, responderRedeemPKH: nil)

            responderSwap = Swap(
                    id: "", state: .responded, initiator: false, initiatorCoinCode: "BTC", responderCoinCode: "BCH", 
                    rate: 0, amount: 0, secretHash: Data(), secret: nil,
                    initiatorTimestamp: nil, responderTimestamp: nil, refundPKId: nil, redeemPKId: nil,
                    initiatorRefundPKH: Data(), initiatorRedeemPKH: Data(), responderRefundPKH: nil, responderRedeemPKH: nil)

            stub(mockInitiator) { mock in
                when(mock.swap.get).thenReturn(initiatorSwap)
                when(mock.proceedNext()).thenDoNothing()
            }
            stub(mockResponder) { mock in
                when(mock.swap.get).thenReturn(responderSwap)
                when(mock.proceedNext()).thenDoNothing()
            }
            stub(mockStorage) { mock in
                when(mock.swapsInProgress()).thenReturn([initiatorSwap, responderSwap])
            }
            stub(mockFactory) { mock in
                when(mock.swapInitiator(swap: equal(to: initiatorSwap))).thenReturn(mockInitiator)
                when(mock.swapResponder(swap: equal(to: responderSwap))).thenReturn(mockResponder)
            }

            kit = SwapKit(storage: mockStorage, factory: mockFactory)
            kit.load()
        }

        afterEach {
            reset(mockStorage, mockFactory, mockInitiator, mockResponder)
            kit = nil
            initiatorSwap = nil
            responderSwap = nil
        }

        describe("#proceedNext") {
            it("calls proceedNext on each swap") {
                try! kit.proceedNext()

                verify(mockInitiator).proceedNext()
                verify(mockResponder).proceedNext()
            }
        }
    }
}
