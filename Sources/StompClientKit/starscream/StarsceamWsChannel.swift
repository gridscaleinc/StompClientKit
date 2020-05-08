//
//  File.swift
//  
//
//  Created by gridscale on 2020/05/03.
//

import Foundation
import Starscream

class StarscreamWSChannel: WebSocketChannel, WebSocketDelegate {
    
    private var _delegate : WebSocketChannelDelegate = DefaultDelegate()
    private var _ws: WebSocket
    private var _endpoint :URLRequest?
    
    required init(url: String) {
        let request = URLRequest(url: URL(string: url)!)
        _endpoint = request
        self._ws = WebSocket(request: request)
        self._ws.delegate = self
    }
    
    required init(url: URLRequest) {
        self._endpoint = url
        self._ws = WebSocket(request: url)
        self._ws.delegate = self
        
    }
    
    func connect() {
        _ws.connect()
    }
    
    func disconnect(closeCode: UInt16) {
        _ws.disconnect(closeCode: closeCode)
    }
    
    func write(data: Data) {
        _ws.write(data: data)
    }
    
    /**
     * Sending text to websocket server.
     */
    func write(text: Data) {
        _ws.write(stringData: text, completion: {})
    }
    
    /**
     *
     */
    public var delegate: WebSocketChannelDelegate {
        get {
            return _delegate
        }
        set {
            _delegate = newValue
        }
    }
    
    func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
            case .connected(let headers):
                print("websocket is connected: \(headers)")
                _delegate.onChannelConnected()

            case .disconnected(let reason, let code):
                print("websocket is disconnected: \(reason) with code: \(code)")
                _delegate.onChannelDisConnected()
            
            case .text(let string):
                print("Received text: \(string)")
                _delegate.onText(received: string)

            case .binary(let data):
                // Exception: a stomp client expects no binary data
                print("Received data: \(data.count)")

            case .ping(_):
                break

            case .pong(_):
                break

            case .viabilityChanged(_):
                break

            case .reconnectSuggested(_):
                break

            case .cancelled:
                break
            case .error(let error):
                _delegate.onChannelError(error!)
            }
    }
    
    
}

private class DefaultDelegate: WebSocketChannelDelegate {
    /**
     * Default Implementation. doing nothing
     */
    func onChannelConnected() {
        
    }
    
    /**
     * Default Implementation. doing nothing
     */
    func onChannelDisConnected() {
        
    }
    
    /**
     * Default Implementation. doing nothing
     */
    func onText(received text: String) {
        
    }
    
    /**
     * Default Implementation. doing nothing
     */
    func onChannelError(_ error: Error) {
        
    }
}
