/**
 * (c) 2026, Micro:bit Educational Foundation and contributors
 *
 * SPDX-License-Identifier: MIT
 */

#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

CAP_PLUGIN(SQLiteVanillaPlugin, "SQLiteVanilla",
  CAP_PLUGIN_METHOD(open, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(close, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(execute, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(run, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(query, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(executeSet, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(isDBOpen, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(deleteDatabase, CAPPluginReturnPromise);
  CAP_PLUGIN_METHOD(getVersion, CAPPluginReturnPromise);
)
