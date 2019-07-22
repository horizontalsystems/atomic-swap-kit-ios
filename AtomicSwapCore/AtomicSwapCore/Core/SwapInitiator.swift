class SwapInitiator {
    private let doer: SwapInitiatorDoer

    init(doer: SwapInitiatorDoer) {
        self.doer = doer
    }
}


extension SwapInitiator: ISwapInitiator {

    func proceedNext() throws {
        switch doer.swap.state {
        case .responded:
            try doer.bail()
        case .initiatorBailed:
            try doer.watchResponderBail()
        case .responderBailed:
            try doer.redeem()
        default: ()
        }
    }

}
