/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import AEPCore
import AEPServices
import Foundation

public class Assurance: NSObject, Extension {

    public var name = AssuranceConstants.EXTENSION_NAME
    public var friendlyName = AssuranceConstants.FRIENDLY_NAME
    public static var extensionVersion = AssuranceConstants.EXTENSION_VERSION
    public var metadata: [String: String]?
    public var runtime: ExtensionRuntime

    let datastore = NamedCollectionDataStore(name: AssuranceConstants.EXTENSION_NAME)

    var sessionId: String? {
        get {
            datastore.getString(key: AssuranceConstants.DataStoreKeys.SESSION_ID)
        }
        set {
            datastore.set(key: AssuranceConstants.DataStoreKeys.SESSION_ID, value: newValue)
        }
    }

    // getter for client ID
    lazy var clientID: String = {
        // return with clientId, if it is already available in persistence
        if let persistedClientID = datastore.getString(key: AssuranceConstants.DataStoreKeys.CLIENT_ID) {
            return persistedClientID
        }
        
        // If not generate a new clientId
        let newClientID = UUID().uuidString
        datastore.set(key: AssuranceConstants.DataStoreKeys.CLIENT_ID, value: newClientID)
        return newClientID
        
    }()

    public func onRegistered() {
        registerListener(type: AssuranceConstants.SDKEventType.ASSURANCE, source: EventSource.requestContent, listener: handleAssuranceRequestContent)
    }

    public func onUnregistered() {}

    public required init?(runtime: ExtensionRuntime) {
        self.runtime = runtime
    }

    public func readyForEvent(_ event: Event) -> Bool {
        return true
    }

    private func handleAssuranceRequestContent(event: Event) {
        guard let startSessionData = event.data else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance start session event received with empty data. Dropping event.")
            return
        }

        guard let deeplinkUrlString = startSessionData[AssuranceConstants.EventDataKey.START_SESSION_URL] as? String else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance start session event received with no deeplink url. Dropping event.")
            return
        }

        let deeplinkURL = URL(string: deeplinkUrlString)
        guard let sessionID = deeplinkURL?.params[AssuranceConstants.Deeplink.SESSIONID_KEY] else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Deeplink URL is invalid. Does not contain 'adb_validation_sessionid' query parameter : " + deeplinkUrlString)
            return
        }

        // make sure the sessionID is an UUID string
        guard let _ = UUID(uuidString: sessionID) else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Deeplink URL is invalid. It contains sessionId that is not an valid UUID : " + deeplinkUrlString)
            return
        }

        // Read the environment query parameter from the deeplink url
        let environmentString = deeplinkURL?.params[AssuranceConstants.Deeplink.ENVIRONMENT_KEY] ?? ""
        let environment = AssuranceEnvironment.init(envString: environmentString)

    }

}
