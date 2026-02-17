/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */

import Foundation
import Capacitor

@objc(SQLiteVanillaPlugin)
public class SQLiteVanillaPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "SQLiteVanillaPlugin"
    public let jsName = "SQLiteVanilla"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "open", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "close", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "execute", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "run", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "query", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "executeSet", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "isDBOpen", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "deleteDatabase", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "getVersion", returnType: CAPPluginReturnPromise)
    ]

    private var databases: [String: Database] = [:]
    private let lock = NSLock()

    private func getDB(_ name: String) -> Database? {
        lock.lock()
        defer { lock.unlock() }
        return databases[name]
    }

    private func setDB(_ name: String, _ db: Database) {
        lock.lock()
        defer { lock.unlock() }
        databases[name] = db
    }

    private func removeDB(_ name: String) -> Database? {
        lock.lock()
        defer { lock.unlock() }
        return databases.removeValue(forKey: name)
    }

    @objc func open(_ call: CAPPluginCall) {
        guard let name = call.getString("database") else {
            call.reject("Missing 'database' parameter")
            return
        }
        do {
            if getDB(name) == nil {
                setDB(name, try Database(name: name))
            }
            call.resolve()
        } catch {
            call.reject("Failed to open database: \(error.localizedDescription)")
        }
    }

    @objc func close(_ call: CAPPluginCall) {
        guard let name = call.getString("database") else {
            call.reject("Missing 'database' parameter")
            return
        }
        removeDB(name)?.close()
        call.resolve()
    }

    @objc func execute(_ call: CAPPluginCall) {
        guard let name = call.getString("database"),
              let statements = call.getString("statements") else {
            call.reject("Missing 'database' or 'statements' parameter")
            return
        }
        guard let db = getDB(name) else {
            call.reject("Database '\(name)' is not open")
            return
        }
        do {
            let changes = try db.execute(statements: statements)
            call.resolve([
                "changes": [
                    "changes": changes
                ]
            ])
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func run(_ call: CAPPluginCall) {
        guard let name = call.getString("database"),
              let statement = call.getString("statement") else {
            call.reject("Missing 'database' or 'statement' parameter")
            return
        }
        guard let db = getDB(name) else {
            call.reject("Database '\(name)' is not open")
            return
        }
        do {
            let values = parseValues(call.getArray("values"))
            let result = try db.run(statement: statement, values: values)
            call.resolve([
                "changes": [
                    "changes": result.changes,
                    "lastId": result.lastId
                ]
            ])
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func query(_ call: CAPPluginCall) {
        guard let name = call.getString("database"),
              let statement = call.getString("statement") else {
            call.reject("Missing 'database' or 'statement' parameter")
            return
        }
        guard let db = getDB(name) else {
            call.reject("Database '\(name)' is not open")
            return
        }
        do {
            let values = parseValues(call.getArray("values"))
            let rows = try db.query(statement: statement, values: values)
            call.resolve(["values": rows])
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func executeSet(_ call: CAPPluginCall) {
        guard let name = call.getString("database"),
              let setArray = call.getArray("set") as? [[String: Any]] else {
            call.reject("Missing 'database' or 'set' parameter")
            return
        }
        guard let db = getDB(name) else {
            call.reject("Database '\(name)' is not open")
            return
        }
        let transaction = call.getBool("transaction") ?? true
        do {
            var items: [(statement: String, values: [Any?]?)] = []
            for item in setArray {
                guard let stmt = item["statement"] as? String else {
                    call.reject("Each item in 'set' must have a 'statement' string")
                    return
                }
                let vals = parseValues(item["values"] as? [Any])
                items.append((statement: stmt, values: vals))
            }
            let changes = try db.executeSet(set: items, transaction: transaction)
            call.resolve([
                "changes": [
                    "changes": changes
                ]
            ])
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    @objc func isDBOpen(_ call: CAPPluginCall) {
        guard let name = call.getString("database") else {
            call.reject("Missing 'database' parameter")
            return
        }
        let isOpen = getDB(name)?.isOpen ?? false
        call.resolve(["result": isOpen])
    }

    @objc func deleteDatabase(_ call: CAPPluginCall) {
        guard let name = call.getString("database") else {
            call.reject("Missing 'database' parameter")
            return
        }
        do {
            if let db = removeDB(name) {
                try db.delete()
            } else {
                let tempDb = try Database(name: name)
                try tempDb.delete()
            }
            call.resolve()
        } catch {
            call.reject("Failed to delete database: \(error.localizedDescription)")
        }
    }

    @objc func getVersion(_ call: CAPPluginCall) {
        guard let name = call.getString("database") else {
            call.reject("Missing 'database' parameter")
            return
        }
        guard let db = getDB(name) else {
            call.reject("Database '\(name)' is not open")
            return
        }
        do {
            let version = try db.getVersion()
            call.resolve(["version": version])
        } catch {
            call.reject(error.localizedDescription)
        }
    }

    // MARK: - Helpers

    private func parseValues(_ values: [Any]?) -> [Any?]? {
        guard let values = values else { return nil }
        return values.map { value in
            if value is NSNull {
                return nil
            }
            return value
        }
    }
}
