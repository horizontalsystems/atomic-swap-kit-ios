import XCTest
import Cuckoo
import Nimble
import Quick
@testable import AtomicSwapCore

class SwapInitiatorTests: QuickSpec {
    override func spec() {
        let mockInitiatorBlockchain = MockISwapBlockchain()
        let mockResponderBlockchain = MockISwapBlockchain()
        let mockStorage = MockISwapStorage()

        var swap: Swap!
        var initiator: SwapInitiator!

        beforeEach {
            swap = Swap(
                    id: "", state: .requested, initiator: true, initiatorCoinCode: "BTC", responderCoinCode: "BCH",
                    rate: 0.5, amount: 10, secretHash: Data(repeating: 0, count: 32), secret: Data(repeating: 1, count: 32),
                    initiatorTimestamp: 10, responderTimestamp: 5, refundPKId: "refundPath", redeemPKId: "redeemPath",
                    initiatorRefundPKH: Data(repeating: 2, count: 32), initiatorRedeemPKH: Data(repeating: 3, count: 32),
                    responderRefundPKH: Data(repeating: 4, count: 32), responderRedeemPKH: Data(repeating: 5, count: 32))

            stub(mockInitiatorBlockchain) { mock in
                when(mock.sendBailTransaction(withRedeemKeyHash: any(), refundKeyHash: any(), secretHash: any(), timestamp: any(), amount: any())).thenReturn(MockIBailTransaction())
            }
            stub(mockResponderBlockchain) { mock in
                when(mock.watchBailTransaction(withRedeemKeyHash: any(), refundKeyHash: any(), secretHash: any(), timestamp: any())).thenDoNothing()
                when(mock.sendRedeemTransaction(from: any(), withRedeemKeyHash: any(), redeemPKId: any(), refundKeyHash: any(),
                        secret: any(), secretHash: any(), timestamp: any())).thenDoNothing()
            }
            stub(mockStorage) { mock in
                when(mock.update(swap: any())).thenDoNothing()
            }

            initiator = SwapInitiator(initiatorBlockchain: mockInitiatorBlockchain, responderBlockchain: mockResponderBlockchain, storage: mockStorage, swap: swap)
        }

        afterEach {
            reset(mockInitiatorBlockchain, mockResponderBlockchain, mockStorage)
            swap = nil
            initiator = nil
        }

        describe("#proceedNext") {
            context("when swap state is .responded") {
                beforeEach {
                    swap.state = .responded
                    try! initiator.proceedNext()
                }

                it("sends Bail Transaction on initiatorBlockchain") {
                    verify(mockInitiatorBlockchain).sendBailTransaction(
                            withRedeemKeyHash: equal(to: swap.responderRedeemPKH!), refundKeyHash: equal(to: swap.initiatorRefundPKH),
                            secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.initiatorTimestamp!), amount: equal(to: swap.amount)
                    )
                    verifyNoMoreInteractions(mockInitiatorBlockchain)
                }

                it("updates swap state") {
                    verify(mockStorage).update(swap: equal(to: swap))
                    expect(swap.state).to(equal(Swap.State.initiatorBailed))
                    verifyNoMoreInteractions(mockStorage)
                }

                it("watches for Bail Transaction on responderBlockchain") {
                    verify(mockResponderBlockchain).watchBailTransaction(
                            withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH), refundKeyHash: equal(to: swap.responderRefundPKH!),
                            secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.responderTimestamp!)
                    )
                    verifyNoMoreInteractions(mockResponderBlockchain)
                }
            }

            context("when swap state is .initiatorBailed") {
                beforeEach {
                    swap.state = .initiatorBailed
                    try! initiator.proceedNext()
                }

                it("doesn't do anything on initiatorBlockchain") {
                    verifyNoMoreInteractions(mockInitiatorBlockchain)
                }

                it("doesn't update swap") {
                    expect(swap.state).to(equal(Swap.State.initiatorBailed))
                    verifyNoMoreInteractions(mockStorage)
                }

                it("watches for Bail Transaction on responderBlockchain") {
                    verify(mockResponderBlockchain).watchBailTransaction(
                            withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH), refundKeyHash: equal(to: swap.responderRefundPKH!),
                            secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.responderTimestamp!)
                    )
                    verifyNoMoreInteractions(mockResponderBlockchain)
                }
            }

            context("when swap state is .responderBailed") {
                let mockBailTransaction = MockIBailTransaction()
                let bailTxDetails = Data(repeating: 6, count: 50)

                beforeEach {
                    swap.state = .responderBailed
                    stub(mockResponderBlockchain) { mock in
                        when(mock.bailTransaction(from: any())).thenReturn(mockBailTransaction)
                    }
                }

                afterEach {
                    reset(mockBailTransaction)
                }

                context("when swap is ready for redeem") {
                    beforeEach {
                        swap.responderBailTransaction = bailTxDetails
                        try! initiator.proceedNext()
                    }

                    it("sends Redeem Transaction on responderBlockchain") {
                        verify(mockResponderBlockchain).bailTransaction(from: equal(to: bailTxDetails))
                        verify(mockResponderBlockchain).sendRedeemTransaction(
                                from: any(),
                                withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH),
                                redeemPKId: equal(to: swap.redeemPKId!),
                                refundKeyHash: equal(to: swap.responderRefundPKH!),
                                secret: equal(to: swap.secret!),
                                secretHash: equal(to: swap.secretHash),
                                timestamp: equal(to: swap.responderTimestamp!)
                        )
                        verifyNoMoreInteractions(mockResponderBlockchain)
                    }

                    it("doesn't do anything on initiatorBlockchain") {
                        verifyNoMoreInteractions(mockInitiatorBlockchain)
                    }

                    it("update swap state") {
                        verify(mockStorage).update(swap: equal(to: swap))
                        expect(swap.state).to(equal(Swap.State.initiatorRedeemed))
                        verifyNoMoreInteractions(mockStorage)
                    }
                }

                context("when swap hasn't responderBailTransaction") {
                    it("throws bailTransactionCouldNotBeRestored exception") {
                        swap.responderBailTransaction = nil

                        do {
                            try initiator.proceedNext()
                            XCTFail("Exception expected")
                        } catch let error as SwapInitiator.SwapInitiatorError {
                            XCTAssertEqual(error, SwapInitiator.SwapInitiatorError.bailTransactionCouldNotBeRestored)
                        } catch {
                            XCTFail("Wrong exception thrown")
                        }
                    }
                }
            }
        }

        describe("#start") {
            context("when swap state is .responded") {
                beforeEach {
                    swap.state = .responded
                }

                context("when swap is ready for bail") {
                    beforeEach {
                        try! initiator.start()
                    }

                    it("sends Bail Transaction on initiatorBlockchain") {
                        verify(mockInitiatorBlockchain).sendBailTransaction(
                                withRedeemKeyHash: equal(to: swap.responderRedeemPKH!), refundKeyHash: equal(to: swap.initiatorRefundPKH),
                                secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.initiatorTimestamp!), amount: equal(to: swap.amount)
                        )
                        verifyNoMoreInteractions(mockInitiatorBlockchain)
                    }

                    it("updates swap state") {
                        verify(mockStorage).update(swap: equal(to: swap))
                        expect(swap.state).to(equal(Swap.State.initiatorBailed))
                        verifyNoMoreInteractions(mockStorage)
                    }

                    it("watches for Bail Transaction on responderBlockchain") {
                        verify(mockResponderBlockchain).watchBailTransaction(
                                withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH), refundKeyHash: equal(to: swap.responderRefundPKH!),
                                secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.responderTimestamp!)
                        )
                        verifyNoMoreInteractions(mockResponderBlockchain)
                    }
                }

                context("when swap hasn't responderRedeemPKH") {
                    it("throws swapNotAgreed exception") {
                        swap.state = .responded
                        swap.responderRedeemPKH = nil

                        do {
                            try initiator.start()
                            XCTFail("Exception expected")
                        } catch let error as SwapInitiator.SwapInitiatorError {
                            XCTAssertEqual(error, SwapInitiator.SwapInitiatorError.swapNotAgreed)
                        } catch {
                            XCTFail("Wrong exception thrown")
                        }
                    }
                }

                context("when swap hasn't initiatorTimestamp") {
                    it("throws swapNotAgreed exception") {
                        swap.state = .responded
                        swap.initiatorTimestamp = nil

                        do {
                            try initiator.start()
                            XCTFail("Exception expected")
                        } catch let error as SwapInitiator.SwapInitiatorError {
                            XCTAssertEqual(error, SwapInitiator.SwapInitiatorError.swapNotAgreed)
                        } catch {
                            XCTFail("Wrong exception thrown")
                        }
                    }
                }
            }

            context("when swap state is not .responded") {
                beforeEach {
                    swap.state = .requested
                    try! initiator.start()
                }

                it("doesn't do anything") {
                    verifyNoMoreInteractions(mockInitiatorBlockchain)
                    verifyNoMoreInteractions(mockResponderBlockchain)
                    verifyNoMoreInteractions(mockStorage)
                    expect(swap.state).to(equal(Swap.State.requested))
                }
            }
        }

        describe("#onBailTransactionReceived") {
            let mockBailTransaction = MockIBailTransaction()
            let bailTxDetails = Data(repeating: 6, count: 50)

            beforeEach {
                swap.state = .initiatorBailed
                swap.responderBailTransaction = nil
                stub(mockResponderBlockchain) { mock in
                    when(mock.bailTransaction(from: any())).thenReturn(mockBailTransaction)
                    when(mock.data(from: any())).thenReturn(bailTxDetails)
                }
                initiator.onBailTransactionReceived(bailTransaction: mockBailTransaction)
            }

            afterEach {
                reset(mockBailTransaction)
            }

            it("sends Redeem Transaction on responderBlockchain") {
                verify(mockResponderBlockchain).data(from: any())
                verify(mockResponderBlockchain).bailTransaction(from: equal(to: bailTxDetails))
                verify(mockResponderBlockchain).sendRedeemTransaction(
                        from: any(),
                        withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH),
                        redeemPKId: equal(to: swap.redeemPKId!),
                        refundKeyHash: equal(to: swap.responderRefundPKH!),
                        secret: equal(to: swap.secret!),
                        secretHash: equal(to: swap.secretHash),
                        timestamp: equal(to: swap.responderTimestamp!)
                )
                verifyNoMoreInteractions(mockResponderBlockchain)
            }

            it("doesn't do anything on initiatorBlockchain") {
                verifyNoMoreInteractions(mockInitiatorBlockchain)
            }

            it("update swap state") {
                verify(mockStorage, times(2)).update(swap: equal(to: swap))
                expect(swap.state).to(equal(Swap.State.initiatorRedeemed))
                verifyNoMoreInteractions(mockStorage)
            }

            it("saves responderBailTransaction details") {
                expect(swap.responderBailTransaction).to(equal(bailTxDetails))
            }
        }
    }
}
