/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */

export interface SQLiteVanillaPlugin {
  open(options: { database: string }): Promise<void>;

  close(options: { database: string }): Promise<void>;

  execute(options: { database: string; statements: string }): Promise<{ changes: { changes: number } }>;

  run(options: {
    database: string;
    statement: string;
    values?: unknown[];
  }): Promise<{ changes: { changes: number; lastId: number } }>;

  query(options: {
    database: string;
    statement: string;
    values?: unknown[];
  }): Promise<{ values: Record<string, unknown>[] }>;

  executeSet(options: {
    database: string;
    set: { statement: string; values?: unknown[] }[];
    transaction?: boolean;
  }): Promise<{ changes: { changes: number } }>;

  isDBOpen(options: { database: string }): Promise<{ result: boolean }>;

  deleteDatabase(options: { database: string }): Promise<void>;

  getVersion(options: { database: string }): Promise<{ version: number }>;
}
