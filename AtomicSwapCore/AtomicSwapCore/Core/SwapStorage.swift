import Foundation
import GRDB

open class SwapStorage {
    public var dbPool: DatabasePool

    public init() {
        let url = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        dbPool = try! DatabasePool(path: url.appendingPathComponent("swaps").path)

        try? migrator.migrate(dbPool)
    }

    open var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createSwaps") { db in
            try db.create(table: Swap.databaseTableName) { t in
                t.column(Swap.Columns.id.name, .text).notNull()
                t.column(Swap.Columns.state.name, .integer).notNull()
                t.column(Swap.Columns.initiator.name, .boolean).notNull()
                t.column(Swap.Columns.initiatorCoinCode.name, .text).notNull()
                t.column(Swap.Columns.responderCoinCode.name, .text).notNull()
                t.column(Swap.Columns.rate.name, .double).notNull()
                t.column(Swap.Columns.amount.name, .integer).notNull()
                t.column(Swap.Columns.secretHash.name, .blob).notNull()
                t.column(Swap.Columns.secret.name, .blob)
                t.column(Swap.Columns.initiatorTimestamp.name, .integer)
                t.column(Swap.Columns.responderTimestamp.name, .integer)
                t.column(Swap.Columns.refundPKId.name, .text)
                t.column(Swap.Columns.redeemPKId.name, .text)
                t.column(Swap.Columns.initiatorRefundPKH.name, .blob).notNull()
                t.column(Swap.Columns.initiatorRedeemPKH.name, .blob).notNull()
                t.column(Swap.Columns.responderRefundPKH.name, .blob)
                t.column(Swap.Columns.responderRedeemPKH.name, .blob)
                t.column(Swap.Columns.initiatorBailTransaction.name, .blob)
                t.column(Swap.Columns.responderBailTransaction.name, .blob)

                // TODO: onConflict should abort!!!!!!!
                t.primaryKey([Swap.Columns.id.name], onConflict: .replace)
            }
        }

        return migrator
    }
}

extension SwapStorage : ISwapStorage {

    func swapsInProgress() -> [Swap] {
        return try! dbPool.read { db in
            try Swap
                    .filter((Swap.Columns.initiator == true && Swap.Columns.state != Swap.State.initiatorRedeemed) ||
                            (Swap.Columns.initiator == false && Swap.Columns.state != Swap.State.responderRedeemed))
                    .fetchAll(db)
        }
    }

    public func add(swap: Swap) {
        _ = try! dbPool.write { db in
            try swap.insert(db)
        }
    }

    public func getSwap(id orderId: String) -> Swap? {
        return try! dbPool.read { db in
            try Swap.filter(Swap.Columns.id == orderId).fetchOne(db)
        }
    }


    func update(swap: Swap) {
        _ = try! dbPool.write { db in
            try swap.update(db)
        }
    }

}
