# @microbit/capacitor-sqlite-vanilla

Minimal Capacitor 7 plugin for SQLite on iOS and Android.

No encryption (no crypto export drama). No web support.

**Stumbled across this?** This plugin has intentionally limited scope and has
had no real world use outside of one app. Your goals might be better met via
https://github.com/capacitor-community/sqlite or perhaps
https://capawesome.io/plugins/sqlite/ (commercial).

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

## License

This software is under the MIT open source license.

[SPDX-License-Identifier: MIT](LICENSE)

We use dependencies via the NPM registry as specified by the package.json file under common Open Source licenses.

Full details of each package can be found by running `license-checker`:

```bash
$ npx license-checker --direct --summary --production
```

Omit the flags as desired to obtain more detail.

## Code of conduct

Trust, partnership, simplicity and passion are our core values we live and
breathe in our daily work life and within our projects. Our open-source
projects are no exception. We have an active community which spans the globe
and we welcome and encourage participation and contributions to our projects
by everyone. We work to foster a positive, open, inclusive and supportive
environment and trust that our community respects the micro:bit code of
conduct. Please see our [code of conduct](https://microbit.org/safeguarding/)
which outlines our expectations for all those that participate in our
community and details on how to report any concerns and what would happen
should breaches occur.
