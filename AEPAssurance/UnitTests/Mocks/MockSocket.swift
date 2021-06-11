//
// Copyright 2021 Adobe. All rights reserved.
// This file is licensed to you under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy
// of the License at http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software distributed under
// the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
// OF ANY KIND, either express or implied. See the License for the specific language
// governing permissions and limitations under the License.
//

@testable import AEPAssurance
@testable import AEPCore
import Foundation

class MockSocket: SocketConnectable {
    var socketListener: SocketEventListener
    var socketState: SocketState

    required init(withListener listener: SocketEventListener) {
        self.socketListener = listener
        self.socketState = .CLOSED
    }

    func connect(withUrl url: URL) {}

    func disconnect() {}

    func sendEvent(_ event: AssuranceEvent) {}

    func mockSocketState(state: SocketState) {
        self.socketState = state
    }
}