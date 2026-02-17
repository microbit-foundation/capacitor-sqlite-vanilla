# @microbit/capacitor-sqlite-vanilla

Minimal Capacitor 7 plugin for SQLite on iOS and Android.

No encryption (and no crypto export drama). No web support.

## Supported versions

### Android

Uses `androidx.sqlite:sqlite-bundled` which embeds SQLite compiled from source,
providing a consistent and up-to-date version regardless of the device's OS. This
avoids the fragmentation of Android's system SQLite.

### iOS

Uses the system `sqlite3` framework. The SQLite version depends on the user's OS
version — the minimum is **SQLite 3.32.3** (iOS 14, the lowest version supported
by Capacitor 7). Notable features unavailable on older iOS versions include:

- `RETURNING` clause and `ALTER TABLE DROP COLUMN` (3.35.0, iOS 15+)
- `STRICT` tables (3.37.0, iOS 15.4+)
- Built-in JSON operators `->` / `->>` (3.38.0, iOS 16+)
- `RIGHT` and `FULL OUTER JOIN` (3.39.0, iOS 16+)

### BLOB handling

BLOB columns in query results are returned as arrays of unsigned byte values (0–255),
e.g. `[72, 101, 108, 108, 111]`. This matches the behaviour of the Capacitor community
SQLite plugin but is inefficient for large values — consider storing binary data as
base64-encoded TEXT instead.

## API

### Bridge methods

| Method                                  | Description                                        |
| --------------------------------------- | -------------------------------------------------- |
| `open({name})`                          | Open or create a database                          |
| `close({name})`                         | Close a database                                   |
| `execute({name, statements})`           | Execute raw SQL (DDL, multi-statement)             |
| `run({name, statement, values?})`       | Parameterized write, returns `{changes, lastId}`   |
| `query({name, statement, values?})`     | Parameterized read, returns `{values: [...]}`      |
| `executeSet({name, set, transaction?})` | Multiple parameterized statements in a transaction |
| `isDBOpen({name})`                      | Check if a database is open                        |
| `deleteDatabase({name})`                | Delete a database file                             |
| `getVersion({name})`                    | Get SQLite `user_version` pragma                   |

### TypeScript wrappers

`SQLiteConnection` and `SQLiteDBConnection` provide a convenience API over the bridge:

```typescript
import { SQLiteVanilla, SQLiteConnection } from '@microbit/capacitor-sqlite-vanilla';

const db = await sqlite.createConnection('my-db');

await db.execute('CREATE TABLE IF NOT EXISTS items (id TEXT PRIMARY KEY, name TEXT)');
await db.run('INSERT INTO items (id, name) VALUES (?, ?)', ['1', 'Example']);
const { values } = await db.query('SELECT id, name FROM items');
await db.close();
```

## Build

```
npm install
npm run build
```
