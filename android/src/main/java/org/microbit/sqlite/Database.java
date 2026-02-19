/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */
package org.microbit.sqlite;

import static androidx.sqlite.SQLite.SQLITE_DATA_BLOB;
import static androidx.sqlite.SQLite.SQLITE_DATA_FLOAT;
import static androidx.sqlite.SQLite.SQLITE_DATA_INTEGER;
import static androidx.sqlite.SQLite.SQLITE_DATA_NULL;
import static androidx.sqlite.SQLite.SQLITE_DATA_TEXT;
import static androidx.sqlite.driver.bundled.BundledSQLite.SQLITE_OPEN_CREATE;
import static androidx.sqlite.driver.bundled.BundledSQLite.SQLITE_OPEN_FULLMUTEX;
import static androidx.sqlite.driver.bundled.BundledSQLite.SQLITE_OPEN_READWRITE;

import android.content.Context;
import androidx.sqlite.SQLiteConnection;
import androidx.sqlite.SQLiteStatement;
import androidx.sqlite.driver.bundled.BundledSQLiteDriver;
import com.getcapacitor.JSArray;
import com.getcapacitor.JSObject;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import org.json.JSONArray;
import org.json.JSONException;

class Database {

    private SQLiteConnection connection;
    private final String name;
    private final String path;

    Database(Context context, String name) {
        this.name = name;
        File dbFile = new File(context.getDatabasePath(name + ".db").getPath());
        dbFile.getParentFile().mkdirs();
        this.path = dbFile.getAbsolutePath();

        BundledSQLiteDriver driver = new BundledSQLiteDriver();
        this.connection = driver.open(this.path, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX);

        // Standard pragmas for mobile use.
        execute("PRAGMA foreign_keys = ON;");
        execute("PRAGMA journal_mode = WAL;");
    }

    boolean isOpen() {
        return connection != null;
    }

    void close() {
        if (connection != null) {
            connection.close();
            connection = null;
        }
    }

    // Execute raw SQL (DDL, multi-statement).
    long execute(String statements) {
        if (connection == null) {
            throw new IllegalStateException("Database is not open");
        }
        for (String sql : statements.split(";")) {
            String trimmed = sql.trim();
            if (trimmed.isEmpty()) {
                continue;
            }
            SQLiteStatement stmt = connection.prepare(trimmed + ";");
            try {
                stmt.step();
            } finally {
                stmt.close();
            }
        }
        return getChanges();
    }

    // Run a single parameterized write statement.
    long[] run(String statement, JSONArray values) throws JSONException {
        if (connection == null) {
            throw new IllegalStateException("Database is not open");
        }
        SQLiteStatement stmt = connection.prepare(statement);
        try {
            bindValues(stmt, values);
            stmt.step();

            // Get changes and last insert rowid.
            long changes = getChanges();
            long lastId = getLastInsertRowId();
            return new long[] { changes, lastId };
        } finally {
            stmt.close();
        }
    }

    // Execute a parameterized read query.
    List<JSObject> query(String statement, JSONArray values) throws JSONException {
        if (connection == null) {
            throw new IllegalStateException("Database is not open");
        }
        SQLiteStatement stmt = connection.prepare(statement);
        try {
            bindValues(stmt, values);

            List<JSObject> rows = new ArrayList<>();
            int columnCount = stmt.getColumnCount();

            while (stmt.step()) {
                JSObject row = new JSObject();
                for (int i = 0; i < columnCount; i++) {
                    String colName = stmt.getColumnName(i);
                    int type = stmt.getColumnType(i);
                    switch (type) {
                        case SQLITE_DATA_NULL:
                            row.put(colName, JSObject.NULL);
                            break;
                        case SQLITE_DATA_INTEGER:
                            row.put(colName, stmt.getLong(i));
                            break;
                        case SQLITE_DATA_FLOAT:
                            row.put(colName, stmt.getDouble(i));
                            break;
                        case SQLITE_DATA_BLOB:
                            byte[] blob = stmt.getBlob(i);
                            JSONArray blobArray = new JSONArray();
                            for (byte b : blob) {
                                blobArray.put(b & 0xFF);
                            }
                            row.put(colName, blobArray);
                            break;
                        case SQLITE_DATA_TEXT:
                        default:
                            row.put(colName, stmt.getText(i));
                            break;
                    }
                }
                rows.add(row);
            }
            return rows;
        } finally {
            stmt.close();
        }
    }

    // Execute multiple parameterized statements in a transaction.
    long executeSet(List<String[]> set, List<JSONArray> valuesList, boolean transaction) throws JSONException {
        if (transaction) {
            execute("BEGIN TRANSACTION;");
        }
        long totalChanges = 0;
        try {
            for (int i = 0; i < set.size(); i++) {
                long[] result = run(set.get(i)[0], valuesList.get(i));
                totalChanges += result[0];
            }
            if (transaction) {
                execute("COMMIT;");
            }
        } catch (Exception e) {
            if (transaction) {
                try {
                    execute("ROLLBACK;");
                } catch (Exception ignored) {}
            }
            throw e;
        }
        return totalChanges;
    }

    int getVersion() throws JSONException {
        List<JSObject> rows = query("PRAGMA user_version;", null);
        if (!rows.isEmpty() && rows.get(0).has("user_version")) {
            return rows.get(0).getInt("user_version");
        }
        return 0;
    }

    void delete(Context context) {
        close();
        File dbFile = new File(path);
        if (dbFile.exists()) {
            dbFile.delete();
        }
        // Also remove WAL and SHM files.
        new File(path + "-wal").delete();
        new File(path + "-shm").delete();
    }

    private long getChanges() {
        SQLiteStatement stmt = connection.prepare("SELECT changes()");
        try {
            stmt.step();
            return stmt.getLong(0);
        } finally {
            stmt.close();
        }
    }

    private long getLastInsertRowId() {
        SQLiteStatement stmt = connection.prepare("SELECT last_insert_rowid()");
        try {
            stmt.step();
            return stmt.getLong(0);
        } finally {
            stmt.close();
        }
    }

    private void bindValues(SQLiteStatement stmt, JSONArray values) throws JSONException {
        if (values == null) return;
        for (int i = 0; i < values.length(); i++) {
            int idx = i + 1; // SQLite bind indices are 1-based.
            if (values.isNull(i)) {
                stmt.bindNull(idx);
            } else {
                Object value = values.get(i);
                if (value instanceof Long || value instanceof Integer) {
                    stmt.bindLong(idx, ((Number) value).longValue());
                } else if (value instanceof Double || value instanceof Float) {
                    stmt.bindDouble(idx, ((Number) value).doubleValue());
                } else if (value instanceof Boolean) {
                    stmt.bindLong(idx, ((Boolean) value) ? 1 : 0);
                } else {
                    stmt.bindText(idx, value.toString());
                }
            }
        }
    }
}
