import XCTest
import Cuckoo
import Nimble
import Quick
@testable import AtomicSwapCore

class SwapResponderTests: QuickSpec {
    override func spec() {
        let mockInitiatorBlockchain = MockISwapBlockchain()
        let mockResponderBlockchain = MockISwapBlockchain()
        let mockStorage = MockISwapStorage()

        let mockResponderBailTransaction = MockIBailTransaction()
        let responderBailTxDetails = Data(repeating: 6, count: 50)

        var swap: Swap!
        var responder: SwapResponder!

        beforeEach {
            swap = Swap(
                    id: "", state: .requested, initiator: true, initiatorCoinCode: "BTC", responderCoinCode: "BCH",
                    rate: 0.5, amount: 10, secretHash: Data(repeating: 0, count: 32), secret: Data(repeating: 1, count: 32),
                    initiatorTimestamp: 10, responderTimestamp: 5, refundPKId: "refundPath", redeemPKId: "redeemPath",
                    initiatorRefundPKH: Data(repeating: 2, count: 32), initiatorRedeemPKH: Data(repeating: 3, count: 32),
                    responderRefundPKH: Data(repeating: 4, count: 32), responderRedeemPKH: Data(repeating: 5, count: 32))

            stub(mockInitiatorBlockchain) { mock in
                when(mock.watchBailTransaction(withRedeemKeyHash: any(), refundKeyHash: any(), secretHash: any(), timestamp: any())).thenDoNothing()
                when(mock.sendRedeemTransaction(from: any(), withRedeemKeyHash: any(), redeemPKId: any(), refundKeyHash: any(),
                        secret: any(), secretHash: any(), timestamp: any())).thenDoNothing()
            }
            stub(mockResponderBlockchain) { mock in
                when(mock.bailTransaction(from: equal(to: responderBailTxDetails))).thenReturn(mockResponderBailTransaction)
                when(mock.data(from: equal(to: mockResponderBailTransaction, equalWhen: bailTxEqualFunction))).thenReturn(responderBailTxDetails)
                when(mock.sendBailTransaction(withRedeemKeyHash: any(), refundKeyHash: any(), secretHash: any(), timestamp: any(), amount: any())).thenReturn(mockResponderBailTransaction)
                when(mock.watchRedeemTransaction(fromTransaction: any())).thenDoNothing()
            }

            stub(mockStorage) { mock in
                when(mock.update(swap: any())).thenDoNothing()
            }

            responder = SwapResponder(initiatorBlockchain: mockInitiatorBlockchain, responderBlockchain: mockResponderBlockchain, storage: mockStorage, swap: swap)
        }

        afterEach {
            reset(mockInitiatorBlockchain, mockResponderBlockchain, mockStorage)
            swap = nil
            responder = nil
        }

        describe("#proceedNext") {
            context("when swap state is .responded") {
                beforeEach {
                    swap.state = .responded
                }

                context("when swap is ready") {
                    beforeEach {
                        try! responder.proceedNext()
                    }

                    it("doesn't do anything on initiatorBlockchain") {
                        verifyNoMoreInteractions(mockResponderBlockchain)
                    }

                    it("doesn't update swap") {
                        verifyNoMoreInteractions(mockStorage)
                    }

                    it("watches for Bail Transaction on initiatorBlockchain") {
                        verify(mockInitiatorBlockchain).watchBailTransaction(
                                withRedeemKeyHash: equal(to: swap.responderRedeemPKH!), refundKeyHash: equal(to: swap.initiatorRefundPKH),
                                secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.initiatorTimestamp!)
                        )
                        verifyNoMoreInteractions(mockInitiatorBlockchain)
                    }
                }

                context("when swap hasn't responderRedeemPKH") {
                    beforeEach {
                        swap.responderRedeemPKH = nil
                    }

                    it("throws swapNotAgreed error") {
                        do {
                            try responder.proceedNext()
                            XCTFail("Expecting error")
                        } catch let error as SwapResponder.SwapResponderError {
                            XCTAssertEqual(error, SwapResponder.SwapResponderError.swapNotAgreed)
                        } catch {
                            XCTFail("Wrong error thrown")
                        }
                    }
                }
            }

            context("when swap state is .initiatorBailed") {
                beforeEach {
                    swap.state = .initiatorBailed
                    swap.responderBailTransaction = responderBailTxDetails

                    try! responder.proceedNext()
                }

                it("sends Bail Transaction on responderBlockchain") {
                    verify(mockResponderBlockchain).sendBailTransaction(
                            withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH), refundKeyHash: equal(to: swap.responderRefundPKH!),
                            secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.responderTimestamp!), amount: equal(to: swap.amount * swap.rate)
                    )
                }

                it("updates swap state") {
                    verify(mockStorage).update(swap: equal(to: swap))
                    expect(swap.state).to(equal(Swap.State.responderBailed))
                    verifyNoMoreInteractions(mockStorage)
                }

                it("watches for Redeem Transaction on responderBlockchain") {
                    verify(mockResponderBlockchain).watchRedeemTransaction(fromTransaction: equal(to: mockResponderBailTransaction, equalWhen: bailTxEqualFunction))
                    verifyNoMoreInteractions(mockInitiatorBlockchain)
                }
            }

            context("when swap state is .responderBailed") {
                beforeEach {
                    swap.state = .responderBailed
                }

                context("when swap has responderBailTransaction exists") {
                    beforeEach {
                        swap.responderBailTransaction = responderBailTxDetails
                    }

                    it("watches for Redeem Transaction on responderBlockchain") {
                        try! responder.proceedNext()

                        verify(mockResponderBlockchain).watchRedeemTransaction(fromTransaction: equal(to: mockResponderBailTransaction, equalWhen: bailTxEqualFunction))
                        verifyNoMoreInteractions(mockInitiatorBlockchain)
                    }
                }

                context("when swap hasn't responderBailTransaction") {
                    beforeEach {
                        swap.responderBailTransaction = nil
                    }

                    it("throws bailTransactionCouldNotBeRestored error") {
                        do {
                            try responder.proceedNext()
                            XCTFail("Expecting error")
                        } catch let error as SwapResponder.SwapResponderError {
                            XCTAssertEqual(error, SwapResponder.SwapResponderError.bailTransactionCouldNotBeRestored)
                        } catch {
                            XCTFail("Wrong error thrown")
                        }
                    }
                }
            }

            context("when swap statis is .initiatorRedeemed") {
                let mockInitiatorBailTransaction = MockIBailTransaction()
                let initiatorBailTxDetails = Data(repeating: 6, count: 50)

                beforeEach {
                    swap.state = .initiatorRedeemed
                    stub(mockInitiatorBlockchain) { mock in
                        when(mock.bailTransaction(from: any())).thenReturn(mockInitiatorBailTransaction)
                    }
                }

                afterEach {
                    reset(mockInitiatorBailTransaction)
                }

                context("when swap is ready for redeem") {
                    beforeEach {
                        swap.initiatorBailTransaction = initiatorBailTxDetails
                        try! responder.proceedNext()
                    }

                    it("sends Redeem Transaction on initiatorBlockchain") {
                        verify(mockInitiatorBlockchain).bailTransaction(from: equal(to: initiatorBailTxDetails))
                        verify(mockInitiatorBlockchain).sendRedeemTransaction(
                                from: any(),
                                withRedeemKeyHash: equal(to: swap.responderRedeemPKH!),
                                redeemPKId: equal(to: swap.redeemPKId!),
                                refundKeyHash: equal(to: swap.initiatorRefundPKH),
                                secret: equal(to: swap.secret!),
                                secretHash: equal(to: swap.secretHash),
                                timestamp: equal(to: swap.initiatorTimestamp!)
                        )
                        verifyNoMoreInteractions(mockInitiatorBlockchain)
                    }

                    it("doesn't do anything on responderBlockchain") {
                        verifyNoMoreInteractions(mockResponderBlockchain)
                    }

                    it("update swap state") {
                        verify(mockStorage).update(swap: equal(to: swap))
                        expect(swap.state).to(equal(Swap.State.responderRedeemed))
                        verifyNoMoreInteractions(mockStorage)
                    }
                }

                context("when swap hasn't secret") {
                    it("throws swapNotAgreed exception") {
                        swap.secret = nil

                        do {
                            try responder.proceedNext()
                            XCTFail("Exception expected")
                        } catch let error as SwapResponder.SwapResponderError {
                            XCTAssertEqual(error, SwapResponder.SwapResponderError.swapNotAgreed)
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
                    try! responder.start()
                }

                it("watches for Bail Transaction on initiatorBlockchain") {
                    verify(mockInitiatorBlockchain).watchBailTransaction(
                            withRedeemKeyHash: equal(to: swap.responderRedeemPKH!), refundKeyHash: equal(to: swap.initiatorRefundPKH),
                            secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.initiatorTimestamp!)
                    )
                    verifyNoMoreInteractions(mockInitiatorBlockchain)
                }
            }

            context("when swap state is not .responded") {
                beforeEach {
                    swap.state = .requested
                    try! responder.start()
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
            let mockInitiatorBailTransaction = MockIBailTransaction()
            let initiatorBailTxDetails = Data(repeating: 6, count: 50)

            beforeEach {
                swap.state = .responded
                swap.initiatorBailTransaction = nil
                stub(mockInitiatorBlockchain) { mock in
                    when(mock.bailTransaction(from: any())).thenReturn(mockInitiatorBailTransaction)
                    when(mock.data(from: any())).thenReturn(initiatorBailTxDetails)
                }
                responder.onBailTransactionReceived(bailTransaction: mockInitiatorBailTransaction)
            }

            afterEach {
                reset(mockInitiatorBailTransaction)
            }

            it("sends Bail Transaction on responderBlockchain") {
                verify(mockResponderBlockchain).sendBailTransaction(
                        withRedeemKeyHash: equal(to: swap.initiatorRedeemPKH), refundKeyHash: equal(to: swap.responderRefundPKH!),
                        secretHash: equal(to: swap.secretHash), timestamp: equal(to: swap.responderTimestamp!), amount: equal(to: swap.amount * swap.rate)
                )
            }

            it("doesn't do anything on initiatorBlockchain") {
                verify(mockInitiatorBlockchain).data(from: equal(to: mockInitiatorBailTransaction, equalWhen: bailTxEqualFunction))
                verifyNoMoreInteractions(mockInitiatorBlockchain)
            }

            it("update swap state") {
                verify(mockStorage, times(2)).update(swap: equal(to: swap))
                expect(swap.state).to(equal(Swap.State.responderBailed))
                verifyNoMoreInteractions(mockStorage)
            }

            it("saves initiatorBailTransaction details") {
                expect(swap.initiatorBailTransaction).to(equal(initiatorBailTxDetails))
            }

            it("watches for Redeem Transaction on responderBlockchain") {
                verify(mockResponderBlockchain).watchRedeemTransaction(fromTransaction: equal(to: mockResponderBailTransaction, equalWhen: bailTxEqualFunction))
            }
        }

        describe("#onRedeemTransactionReceived") {
            let mockInitiatorBailTransaction = MockIBailTransaction()
            let initiatorBailTxDetails = Data(repeating: 6, count: 50)
            let mockInitiatorRedeemTransaction = MockIRedeemTransaction()
            let extractedSecret = Data(repeating: 9, count: 32)

            beforeEach {
                swap.state = .responderBailed
                swap.initiatorBailTransaction = initiatorBailTxDetails
                stub(mockInitiatorRedeemTransaction) { mock in
                    when(mock.secret.get).thenReturn(extractedSecret)
                }
                stub(mockInitiatorBlockchain) { mock in
                    when(mock.bailTransaction(from: any())).thenReturn(mockInitiatorBailTransaction)
                }
                responder.onRedeemTransactionReceived(redeemTransaction: mockInitiatorRedeemTransaction)
            }

            afterEach {
                reset(mockInitiatorRedeemTransaction)
            }

            it("sends Redeem Transaction on initiatorBlockchain") {
                verify(mockInitiatorBlockchain).bailTransaction(from: equal(to: initiatorBailTxDetails))
                verify(mockInitiatorBlockchain).sendRedeemTransaction(
                        from: any(),
                        withRedeemKeyHash: equal(to: swap.responderRedeemPKH!),
                        redeemPKId: equal(to: swap.redeemPKId!),
                        refundKeyHash: equal(to: swap.initiatorRefundPKH),
                        secret: equal(to: extractedSecret),
                        secretHash: equal(to: swap.secretHash),
                        timestamp: equal(to: swap.initiatorTimestamp!)
                )
                verifyNoMoreInteractions(mockInitiatorBlockchain)
            }

            it("doesn't do anything on responderBlockchain") {
                verifyNoMoreInteractions(mockResponderBlockchain)
            }

            it("update swap state") {
                verify(mockStorage, times(2)).update(swap: equal(to: swap))
                expect(swap.state).to(equal(Swap.State.responderRedeemed))
                expect(swap.secret).to(equal(extractedSecret))
                verifyNoMoreInteractions(mockStorage)
            }
        }
    }
}
