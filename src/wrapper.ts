/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */
import type { SQLiteVanillaPlugin } from './definitions';

/**
 * Wraps a single open database connection, providing a convenient API
 * over the raw Capacitor bridge methods.
 */
export class SQLiteDBConnection {
  constructor(
    private plugin: SQLiteVanillaPlugin,
    private name: string,
  ) {}

  async execute(statements: string): Promise<{ changes: { changes: number } }> {
    return this.plugin.execute({ database: this.name, statements });
  }

  async run(statement: string, values?: unknown[]): Promise<{ changes: { changes: number; lastId: number } }> {
    return this.plugin.run({ database: this.name, statement, values });
  }

  async query(statement: string, values?: unknown[]): Promise<{ values: Record<string, unknown>[] }> {
    return this.plugin.query({ database: this.name, statement, values });
  }

  /**
   * Execute a set of parameterized statements, optionally wrapped in a
   * transaction (default: true).
   */
  async executeTransaction(
    set: { statement: string; values?: unknown[] }[],
  ): Promise<{ changes: { changes: number } }> {
    return this.plugin.executeSet({
      database: this.name,
      set,
      transaction: true,
    });
  }

  async executeSet(
    set: { statement: string; values?: unknown[] }[],
    transaction = true,
  ): Promise<{ changes: { changes: number } }> {
    return this.plugin.executeSet({
      database: this.name,
      set,
      transaction,
    });
  }

  async isOpen(): Promise<boolean> {
    const { result } = await this.plugin.isDBOpen({ database: this.name });
    return result;
  }

  async getVersion(): Promise<number> {
    const { version } = await this.plugin.getVersion({ database: this.name });
    return version;
  }

  async close(): Promise<void> {
    await this.plugin.close({ database: this.name });
  }
}

/**
 * Top-level entry point for managing SQLite databases via the plugin.
 */
export class SQLiteConnection {
  constructor(private plugin: SQLiteVanillaPlugin) {}

  /**
   * Open (or create) a database and return a connection wrapper.
   */
  async createConnection(name: string): Promise<SQLiteDBConnection> {
    await this.plugin.open({ database: name });
    return new SQLiteDBConnection(this.plugin, name);
  }

  async deleteDatabase(name: string): Promise<void> {
    await this.plugin.deleteDatabase({ database: name });
  }
}
