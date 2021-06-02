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
import Foundation

extension Event {
    // MARK: - Event Type/Source Detection
    var isSharedStateEvent: Bool {
        return type == EventType.hub && source == EventSource.sharedState
    }
    
    var isPlacesRequestEvent: Bool {
        return type == EventType.places && source == EventSource.requestContent
    }
    
    var isPlacesResponseEvent: Bool {
        return type == EventType.places && source == EventSource.responseContent
    }
    
    var isRequestNearByPOIEvent : Bool {
        return name == AssuranceConstants.Places.EventName.REQUEST_NEARBY_POI
    }
    
    var isRequestResetEvent : Bool {
        return name == AssuranceConstants.Places.EventName.REQUEST_RESET
    }
    
    var isResponseRegionEvent : Bool {
        return name == AssuranceConstants.Places.EventName.RESPONSE_REGION_EVENT
    }

    // MARK: - EventData values
    var sharedStateOwner: String? {
        return data?[AssuranceConstants.EventDataKey.SHARED_STATE_OWNER] as? String
    }
    
    var poiCount: String {
        return data?[AssuranceConstants.Places.EventDataKeys.COUNT] as? String ?? "-"
    }
    
    var latitude: String {
        return data?[AssuranceConstants.Places.EventDataKeys.LATITUDE] as? String ?? "-"
    }
    
    var longitude: String {
        return data?[AssuranceConstants.Places.EventDataKeys.LONGITUDE] as? String ?? "-"
    }
    
}