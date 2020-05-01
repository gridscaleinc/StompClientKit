//
//  File.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation
import Starscream

//
public typealias MessageHandler = (_ frame : Frame) -> Any

public class StompClient : WebSocketDelegate {
    
    private var endpoint: URL
    public var messageHandler : MessageHandler = {_ in }
    private var underlyWebsocket : WebSocket
    
    public var wsConnected = false
    
    // status of stomp client
    // CONNECTING -> CONNECTED -> DISCONNECTED
    public var status = StompStatus.STARTING
    
    // STOMP Protocol version
    // initially UNKNOWN was set, after handshake, the really version will be set.
    private var version = StompVersions.UNKNOWN
    
    // STOMP Heart beat value. 0 means not send.
    private var heartbeat = 0
    
    // On Connected Handling callback hook.
    private var onConnected : (_ client: StompClient) -> Any = {_ in }
    
    // intilize the underlying websocket object.
    // at this point, the websocket had not connected to server yet.
    public init(endpoint url : String) {
        self.endpoint = URL(string: url)!
        var request = URLRequest(url: endpoint)
        
        request.timeoutInterval = 5
        underlyWebsocket = WebSocket(request: request)
        underlyWebsocket.delegate = self
    }
    
    //
    public func startConnect (onConnected handler : @escaping (_ client: StompClient) -> Any) {
        self.onConnected = handler
        underlyWebsocket.connect()
        
    }
    
    //
    public func subscribe(to topic : String)  -> StompClient {
        var frame = Frame.subscribeFrame()
        frame.addHeader(FrameHeader(k: Headers.ID.rawValue, v: "sub-0"))
        frame.addHeader(FrameHeader(k: Headers.DESTINATION.rawValue, v: topic))
        frame.addHeader(FrameHeader(k: Headers.ACK.rawValue, v: "client"))
        
        print(frame)
        
        let data = frame.toData()!
        
        underlyWebsocket.write(data: data)
        
        print(String(data: data, encoding: .utf8)!)
        
        return self
    }
    
    //
    public func disconnect() {
        
    }
    
    //
    public func send(_ msg: String) {
        
    }
    
    //
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        switch event {
        case .connected(let headers):
            wsConnected = true
            print("websocket is connected: \(headers)")
            var command = Frame.connectFrame(versions: "1.2,1.1")
            command.addHeader(FrameHeader(k: Headers.HOST.rawValue, v: "192.168.11.5"))
            let data = command.toData()!
            
            underlyWebsocket.write(data: data)
            
            print(String(data: data, encoding: .utf8)!)
            
        case .disconnected(let reason, let code):
            wsConnected = false
            print("websocket is disconnected: \(reason) with code: \(code)")
            
        case .text(let string):
            print("Received text: \(string)")
            // handle stomp frame
            handleFrame(text: string)
            
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
            wsConnected = false
            
        case .error(let error):
            wsConnected = false
            handleError(error )
        }
    }
    
    // Handle Frame text from server, update client status or call message handler
    // according to the content of the frame.
    func handleFrame(text: String) {
        // check
        
        let parser = FrameParser(as: .VER1_2)
        parser.parse(text: text)
        
        let frame = parser.resultFrame
        
        if (frame == nil) {
            return
        }
        
        // if CONNECTED
        if (frame!.isConnected) {
            status = .CONNECTED
            // retrieve heart beat
            // retrieve protocol version
            
            // call back to onConnected function
            onConnected(self)
            
        } else if ( frame!.isMessage) {
        // if MESSAGE
            messageHandler(frame!)
            
        } else if ( frame!.isReceipt) {
        // if RECEIPT
            
        } else if ( frame!.isError) {
        // if ERROR
            
        } else {
            // exception
        }
    }
    
    //
    func handleError(_ error : Error?) {
        
    }
}
