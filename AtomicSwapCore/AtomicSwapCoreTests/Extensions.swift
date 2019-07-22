import AtomicSwapCore

let bailTxEqualFunction: (IBailTransaction, IBailTransaction) -> Bool = { a, b in
    let aMock = a as! MockIBailTransaction
    let bMock = b as! MockIBailTransaction

    return ObjectIdentifier(aMock) == ObjectIdentifier(bMock)
}
