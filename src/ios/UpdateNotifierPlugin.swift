/**
 * Copyright 2020 Ayogo Health Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Siren

@objc(CDVUpdateNotifierPlugin)
class UpdateNotifierPlugin : CDVPlugin {

    @objc(checkForUpdate:)
    func checkForUpdate(command: CDVInvokedUrlCommand) {
        runUpdateCheck(callbackId: command.callbackId)
    }

    private func runUpdateCheck(callbackId: String) {
        let disableUpdateCheck = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed")?["DisableUpdateCheck"] as? String
        if disableUpdateCheck == "true" {
            let result = CDVPluginResult(
                status: CDVCommandStatus_OK,
                messageAs: [
                    "status": "continue"
                ]
            )
            self.commandDelegate.send(result, callbackId: callbackId)
            return
        }

        let siren = Siren.shared

        let globalRules: Rules
        if let alertType = self.commandDelegate.settings["sirenalerttype"] as? String {
            switch alertType {
            case "critical":
                globalRules = .critical
            case "annoying":
                globalRules = .annoying
            case "persistent":
                globalRules = .persistent
            case "hinting":
                globalRules = .hinting
            case "relaxed":
                globalRules = .relaxed
            default:
                globalRules = .default
            }
        } else {
            globalRules = .critical
        }

        siren.rulesManager = RulesManager(
            globalRules: globalRules,
            showAlertAfterCurrentVersionHasBeenReleasedForDays: 0
        )

        if let countryCode = self.commandDelegate.settings["sirencountrycode"] as? String {
            siren.apiManager = APIManager(countryCode: countryCode)
        }

        DispatchQueue.main.async {
            siren.wail(performCheck: .onDemand) { results in
                switch results {
                case .success(_):
                    let result = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: [
                            "status": "updateAvailable"
                        ]
                    )
                    self.commandDelegate.send(result, callbackId: callbackId)

                case .failure(_):
                    let result = CDVPluginResult(
                        status: CDVCommandStatus_OK,
                        messageAs: [
                            "status": "continue"
                        ]
                    )
                    self.commandDelegate.send(result, callbackId: callbackId)
                }
            }
        }
    }
}
