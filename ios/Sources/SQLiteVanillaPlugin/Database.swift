/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */

import Foundation
import SQLite3

enum DatabaseError: LocalizedError {
    case openFailed(String)
    case prepareFailed(String)
    case executeFailed(String)

    var errorDescription: String? {
        switch self {
        case .openFailed(let msg): return "Failed to open database: \(msg)"
        case .prepareFailed(let msg): return "Failed to prepare statement: \(msg)"
        case .executeFailed(let msg): return "Execute failed: \(msg)"
        }
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

class Database {
    private var db: OpaquePointer?
    let name: String
    let path: String

    init(name: String) throws {
        self.name = name
        let fileManager = FileManager.default
        guard let appSupportDir = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw DatabaseError.openFailed("could not locate Application Support directory")
        }
        try fileManager.createDirectory(at: appSupportDir, withIntermediateDirectories: true)
        self.path = appSupportDir.appendingPathComponent("\(name).db").path

        var dbPointer: OpaquePointer?
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        let result = sqlite3_open_v2(path, &dbPointer, flags, nil)
        guard result == SQLITE_OK, let dbPointer = dbPointer else {
            let msg = dbPointer.flatMap { String(cString: sqlite3_errmsg($0)) } ?? "unknown error"
            sqlite3_close(dbPointer)
            throw DatabaseError.openFailed(msg)
        }
        self.db = dbPointer

        // Standard pragmas for mobile use.
        try executeRaw("PRAGMA foreign_keys = ON;")
        try executeRaw("PRAGMA journal_mode = WAL;")
    }

    var isOpen: Bool { db != nil }

    func close() {
        if let db = db {
            sqlite3_close_v2(db)
        }
        db = nil
    }

    // MARK: - Execute (raw SQL, possibly multi-statement)

    func execute(statements: String) throws -> Int {
        try executeRaw(statements)
        return Int(sqlite3_changes(db))
    }

    private func executeRaw(_ sql: String) throws {
        guard let db = db else {
            throw DatabaseError.executeFailed("database is not open")
        }
        var errMsg: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(db, sql, nil, nil, &errMsg)
        if result != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown error"
            sqlite3_free(errMsg)
            throw DatabaseError.executeFailed(msg)
        }
    }

    // MARK: - Run (single parameterized write)

    struct RunResult {
        let changes: Int
        let lastId: Int64
    }

    func run(statement: String, values: [Any?]?) throws -> RunResult {
        guard let db = db else {
            throw DatabaseError.executeFailed("database is not open")
        }
        var stmtPtr: OpaquePointer?
        guard sqlite3_prepare_v2(db, statement, -1, &stmtPtr, nil) == SQLITE_OK,
              let stmt = stmtPtr else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }

        try bindValues(stmt: stmt, values: values)

        let stepResult = sqlite3_step(stmt)
        guard stepResult == SQLITE_DONE || stepResult == SQLITE_ROW else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.executeFailed(msg)
        }

        return RunResult(
            changes: Int(sqlite3_changes(db)),
            lastId: sqlite3_last_insert_rowid(db)
        )
    }

    // MARK: - Query (parameterized read)

    func query(statement: String, values: [Any?]?) throws -> [[String: Any]] {
        guard let db = db else {
            throw DatabaseError.executeFailed("database is not open")
        }
        var stmtPtr: OpaquePointer?
        guard sqlite3_prepare_v2(db, statement, -1, &stmtPtr, nil) == SQLITE_OK,
              let stmt = stmtPtr else {
            let msg = String(cString: sqlite3_errmsg(db))
            throw DatabaseError.prepareFailed(msg)
        }
        defer { sqlite3_finalize(stmt) }

        try bindValues(stmt: stmt, values: values)

        var rows: [[String: Any]] = []
        let columnCount = sqlite3_column_count(stmt)

        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]
            for i in 0..<columnCount {
                let name = String(cString: sqlite3_column_name(stmt, i))
                let type = sqlite3_column_type(stmt, i)
                switch type {
                case SQLITE_INTEGER:
                    row[name] = sqlite3_column_int64(stmt, i)
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(stmt, i))
                case SQLITE_BLOB:
                    if let bytes = sqlite3_column_blob(stmt, i) {
                        let length = sqlite3_column_bytes(stmt, i)
                        row[name] = [UInt8](Data(bytes: bytes, count: Int(length)))
                    } else {
                        row[name] = NSNull()
                    }
                case SQLITE_NULL:
                    row[name] = NSNull()
                default:
                    row[name] = NSNull()
                }
            }
            rows.append(row)
        }
        return rows
    }

    // MARK: - Execute set (multiple parameterized statements in a transaction)

    func executeSet(set: [(statement: String, values: [Any?]?)], transaction: Bool) throws -> Int {
        if transaction {
            try executeRaw("BEGIN TRANSACTION;")
        }
        var totalChanges = 0
        do {
            for item in set {
                let result = try run(statement: item.statement, values: item.values)
                totalChanges += result.changes
            }
            if transaction {
                try executeRaw("COMMIT;")
            }
        } catch {
            if transaction {
                try? executeRaw("ROLLBACK;")
            }
            throw error
        }
        return totalChanges
    }

    // MARK: - Version (PRAGMA user_version)

    func getVersion() throws -> Int {
        let rows = try query(statement: "PRAGMA user_version;", values: nil)
        if let row = rows.first, let version = row["user_version"] as? Int64 {
            return Int(version)
        }
        return 0
    }

    // MARK: - Delete

    func delete() throws {
        close()
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: path) {
            try fileManager.removeItem(atPath: path)
        }
        // Also remove WAL and SHM files if present.
        for suffix in ["-wal", "-shm"] {
            let auxPath = path + suffix
            if fileManager.fileExists(atPath: auxPath) {
                try fileManager.removeItem(atPath: auxPath)
            }
        }
    }

    // MARK: - Bind helpers

    private func bindValues(stmt: OpaquePointer, values: [Any?]?) throws {
        guard let values = values else { return }
        for (index, value) in values.enumerated() {
            let idx = Int32(index + 1)
            switch value {
            case nil:
                sqlite3_bind_null(stmt, idx)
            case let intVal as Int64:
                sqlite3_bind_int64(stmt, idx, intVal)
            case let intVal as Int:
                sqlite3_bind_int64(stmt, idx, Int64(intVal))
            case let doubleVal as Double:
                sqlite3_bind_double(stmt, idx, doubleVal)
            case let stringVal as String:
                sqlite3_bind_text(stmt, idx, (stringVal as NSString).utf8String, -1, SQLITE_TRANSIENT)
            case let boolVal as Bool:
                sqlite3_bind_int64(stmt, idx, boolVal ? 1 : 0)
            case is NSNull:
                sqlite3_bind_null(stmt, idx)
            default:
                // Attempt string conversion as fallback.
                if let value = value {
                    let str = "\(value)"
                    sqlite3_bind_text(stmt, idx, (str as NSString).utf8String, -1, SQLITE_TRANSIENT)
                } else {
                    sqlite3_bind_null(stmt, idx)
                }
            }
        }
    }
}
