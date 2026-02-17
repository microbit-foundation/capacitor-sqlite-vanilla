/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */
import { WebPlugin } from '@capacitor/core';

import type { SQLiteVanillaPlugin } from './definitions';

export class SQLiteVanillaWeb extends WebPlugin implements SQLiteVanillaPlugin {
  async open(): Promise<void> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async close(): Promise<void> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async execute(): Promise<{ changes: { changes: number } }> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async run(): Promise<{ changes: { changes: number; lastId: number } }> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async query(): Promise<{ values: Record<string, unknown>[] }> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async executeSet(): Promise<{ changes: { changes: number } }> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async isDBOpen(): Promise<{ result: boolean }> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async deleteDatabase(): Promise<void> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }

  async getVersion(): Promise<{ version: number }> {
    throw this.unavailable('SQLiteVanilla is not available on web');
  }
}
