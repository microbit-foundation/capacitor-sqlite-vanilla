/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */
package org.microbit.sqlite;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

@CapacitorPlugin(name = "SQLiteVanilla")
public class SQLiteVanillaPlugin extends Plugin {

    private final Map<String, Database> databases = new ConcurrentHashMap<>();

    @PluginMethod
    public void open(PluginCall call) {
        String name = call.getString("database");
        if (name == null) {
            call.reject("Missing 'database' parameter");
            return;
        }
        try {
            databases.computeIfAbsent(name, (k) -> new Database(getContext(), k));
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to open database: " + e.getMessage(), e);
        }
    }

    @PluginMethod
    public void close(PluginCall call) {
        String name = call.getString("database");
        if (name == null) {
            call.reject("Missing 'database' parameter");
            return;
        }
        Database db = databases.remove(name);
        if (db != null) {
            db.close();
        }
        call.resolve();
    }

    @PluginMethod
    public void execute(PluginCall call) {
        String name = call.getString("database");
        String statements = call.getString("statements");
        if (name == null || statements == null) {
            call.reject("Missing 'database' or 'statements' parameter");
            return;
        }
        Database db = databases.get(name);
        if (db == null) {
            call.reject("Database '" + name + "' is not open");
            return;
        }
        try {
            long changes = db.execute(statements);
            JSObject changesObj = new JSObject();
            changesObj.put("changes", changes);
            JSObject ret = new JSObject();
            ret.put("changes", changesObj);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void run(PluginCall call) {
        String name = call.getString("database");
        String statement = call.getString("statement");
        if (name == null || statement == null) {
            call.reject("Missing 'database' or 'statement' parameter");
            return;
        }
        Database db = databases.get(name);
        if (db == null) {
            call.reject("Database '" + name + "' is not open");
            return;
        }
        try {
            JSONArray values = call.getArray("values");
            long[] result = db.run(statement, values);
            JSObject changes = new JSObject();
            changes.put("changes", result[0]);
            changes.put("lastId", result[1]);
            JSObject ret = new JSObject();
            ret.put("changes", changes);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void query(PluginCall call) {
        String name = call.getString("database");
        String statement = call.getString("statement");
        if (name == null || statement == null) {
            call.reject("Missing 'database' or 'statement' parameter");
            return;
        }
        Database db = databases.get(name);
        if (db == null) {
            call.reject("Database '" + name + "' is not open");
            return;
        }
        try {
            JSONArray values = call.getArray("values");
            List<JSObject> rows = db.query(statement, values);
            JSObject ret = new JSObject();
            ret.put("values", new JSONArray(rows));
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void executeSet(PluginCall call) {
        String name = call.getString("database");
        if (name == null) {
            call.reject("Missing 'database' parameter");
            return;
        }
        Database db = databases.get(name);
        if (db == null) {
            call.reject("Database '" + name + "' is not open");
            return;
        }
        JSONArray setArray = call.getArray("set");
        if (setArray == null) {
            call.reject("Missing 'set' parameter");
            return;
        }
        Boolean transactionParam = call.getBoolean("transaction");
        boolean transaction = transactionParam == null || transactionParam;
        try {
            List<String[]> statements = new ArrayList<>();
            List<JSONArray> valuesList = new ArrayList<>();
            for (int i = 0; i < setArray.length(); i++) {
                JSONObject item = setArray.getJSONObject(i);
                String stmt = item.getString("statement");
                JSONArray vals = item.optJSONArray("values");
                statements.add(new String[] { stmt });
                valuesList.add(vals);
            }
            long totalChanges = db.executeSet(statements, valuesList, transaction);
            JSObject changes = new JSObject();
            changes.put("changes", totalChanges);
            JSObject ret = new JSObject();
            ret.put("changes", changes);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }

    @PluginMethod
    public void isDBOpen(PluginCall call) {
        String name = call.getString("database");
        if (name == null) {
            call.reject("Missing 'database' parameter");
            return;
        }
        Database db = databases.get(name);
        boolean isOpen = db != null && db.isOpen();
        JSObject ret = new JSObject();
        ret.put("result", isOpen);
        call.resolve(ret);
    }

    @PluginMethod
    public void deleteDatabase(PluginCall call) {
        String name = call.getString("database");
        if (name == null) {
            call.reject("Missing 'database' parameter");
            return;
        }
        try {
            Database db = databases.remove(name);
            if (db != null) {
                db.delete(getContext());
            } else {
                Database tempDb = new Database(getContext(), name);
                tempDb.delete(getContext());
            }
            call.resolve();
        } catch (Exception e) {
            call.reject("Failed to delete database: " + e.getMessage(), e);
        }
    }

    @PluginMethod
    public void getVersion(PluginCall call) {
        String name = call.getString("database");
        if (name == null) {
            call.reject("Missing 'database' parameter");
            return;
        }
        Database db = databases.get(name);
        if (db == null) {
            call.reject("Database '" + name + "' is not open");
            return;
        }
        try {
            int version = db.getVersion();
            JSObject ret = new JSObject();
            ret.put("version", version);
            call.resolve(ret);
        } catch (Exception e) {
            call.reject(e.getMessage(), e);
        }
    }
}
