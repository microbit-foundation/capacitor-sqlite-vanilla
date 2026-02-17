/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */
import { registerPlugin } from '@capacitor/core';

import type { SQLiteVanillaPlugin } from './definitions';

const SQLiteVanilla = registerPlugin<SQLiteVanillaPlugin>('SQLiteVanilla', {
  web: () => import('./web').then((m) => new m.SQLiteVanillaWeb()),
});

export * from './definitions';
export * from './wrapper';
export { SQLiteVanilla };
