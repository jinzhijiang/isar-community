/*
 * Copyright (c) 2024
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import {
  FlutterPlugin,
  FlutterPluginBinding
} from '@ohos/flutter_ohos/src/main/ets/embedding/engine/plugins/FlutterPlugin';

const TAG: string = "IsarFlutterLibsPlugin";

/**
 * IsarFlutterLibsPlugin for Ohos
 * This plugin is mainly used to ensure the native library is loaded.
 * Flutter will automatically load .so files from the libs directory.
 */
export default class IsarFlutterLibsPlugin implements FlutterPlugin {
  private pluginBinding: FlutterPluginBinding | null = null;

  constructor() {
  }

  getUniqueClassName(): string {
    return TAG;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = binding;
    // The native library will be automatically loaded by Flutter
    // from the libs directory, so no additional setup is needed here
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.pluginBinding = null;
  }

  static registerWith(): void {
    // Registration is handled by Flutter
  }
}

