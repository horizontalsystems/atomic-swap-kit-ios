class SwapResponder {
    private let doer: SwapResponderDoer

    init(doer: SwapResponderDoer) {
        self.doer = doer
    }
}


extension SwapResponder: ISwapResponder {

    func proceedNext() throws {
        switch doer.swap.state {
        case .responded:
            try doer.watchInitiatorBail()
        case .initiatorBailed:
            try doer.bail()
        case .responderBailed:
            try doer.watchInitiatorRedeem()
        case .initiatorRedeemed:
            try doer.redeem()
        default: ()
        }
    }

}
