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

import AEPServices
import Foundation
import WebKit

@available(iOS 13.0, *)
class NativeSocket: NSObject, SocketConnectable, URLSessionDelegate, URLSessionWebSocketDelegate {
    var socketListener: SocketEventListener
    var socketState: SocketState = .UNKNOWN {
        didSet {
            socketListener.webSocket(self, didChangeState: self.socketState)
        }
    }

    // MARK: - Private properties

    private var session: URLSession?
    private var socketTask: URLSessionWebSocketTask?

    // MARK: - SocketConnectable Interfaces

    /// Initialization of native socket connection.
    /// - Parameters:
    ///     - listener: the listener instance to get notified on essential socket events
    required init(withListener listener: SocketEventListener) {
        socketListener = listener
    }

    /// Makes a socket connection with the provided URL
    /// Sets the socket state to `CONNECTING` and attempts to make a connection.
    /// On successful connection the socketListeners `webSocketDidConnect` delegate method is invoked. And the socket state is set to `OPEN`.
    /// On any error,  the socketListeners `webSocketOnError` delegate method is invoked.
    /// - Parameters :
    ///     - url : the socket `URL`
    func connect(withUrl url: URL) {
        session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        socketTask = session?.webSocketTask(with: url)
        socketTask?.resume()
        registerCallbacks()
        socketState = .CONNECTING
    }

    /// Disconnect the ongoing socket connection.
    /// Sets the socket state to `CLOSING` and attempts for disconnection
    /// On successful disconnection  the socketListeners `webSocketDidDisconnect` delegate method is invoked. And the socket state is set to`CLOSED`.
    /// On any error,  the socketListeners `webSocketOnError` delegate method is invoked.
    func disconnect() {
        socketState = .CLOSING
        socketTask?.cancel(with: .normalClosure, reason: nil)
    }

    func sendEvent(_ event: AssuranceEvent) {
        let jsonData = (try? JSONEncoder().encode(event)) ?? Data()
        let dataString = jsonData.base64EncodedString(options: .endLineWithLineFeed)
        socketTask?.send(URLSessionWebSocketTask.Message.string(dataString), completionHandler: { [weak self] error in
            if let error = error {
                self?.didReceiveError(error)
            }
        })
    }

    // MARK: - URLSessionWebSocketDelegate methods

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        socketState = .OPEN
        self.socketListener.webSocketDidConnect(self)
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        socketState = .CLOSED
        self.socketListener.webSocketDidDisconnectConnect(self, closeCode.rawValue, reason?.base64EncodedString() ?? "", true)
    }

    // MARK: - Private methods

    private func registerCallbacks() {
        socketTask?.receive {[weak self] result in
            switch result {
            case .success(let response):
                switch response {
                case .string(let message):
                    self?.didReceiveMessage(message)
                case .data(let data):
                    self?.didReceiveBinaryData(data)
                @unknown default:
                    Log.debug(label: AssuranceConstants.LOG_TAG, "Unknown format data received from socket. Ignoring incoming event")
                }
            case .failure(let error):
                self?.didReceiveError(error)
            }
        }
    }

    /// Handle the error from socket connection
    private func didReceiveError(_ error: Error) {
        self.socketListener.webSocketOnError(self)
    }

    /// Handle the incoming string message from socket
    private func didReceiveMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else {
            Log.debug(label: AssuranceConstants.LOG_TAG, "Unable to convert the received socket message to data. Ignoring the incoming event.")
            return
        }
        guard let receivedEvent = AssuranceEvent.from(jsonData: data) else {
            return
        }
        self.socketListener.webSocket(self, didReceiveEvent: receivedEvent)
    }

    /// Handle the incoming binary data from socket
    private func didReceiveBinaryData(_ data: Data) {
        Log.debug(label: AssuranceConstants.LOG_TAG, "Assurance SDK cannot to handle binary data received from socket.")
    }

}