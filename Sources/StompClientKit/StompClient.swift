//
//  StompClient.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation
import Starscream

//
public typealias MessageHandler = (_ frame : Frame) -> Any

/**
 * Stomp Client over Websocket.
 *
 *  Connect to websocket, subscribe to topic,
 *  send and receive message to / from server.
 */
public class StompClient : WebSocketDelegate {
    
    private var endpoint: URL
    public var messageHandler : MessageHandler = {_ in }
    private var underlyWebsocket : WebSocket
    
    /**
     * Optional transaction
     *
     *  this object created automatically by statTrx method, and desctroyed when commit, or abort.
     */
    public var transaction: StompTran?
    
    /**
     * Subscription pool (Dictionary)
     */
    public var subscriptions: [String: Subscription] = [:]
    
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
    
    /**
     * Start to connect to websocket server.
     *
     */
    public func startConnect (onConnected handler : @escaping (_ client: StompClient) -> Any) {
        self.onConnected = handler
        underlyWebsocket.connect()
        
    }
    
    /**
     *
     */
    public func subscribe(to topic : String)  -> StompClient {
        
        var frame = Frame.subscribeFrame()
        
        // TODO generate id
        frame.addHeader(FrameHeader(k: Headers.ID.rawValue, v: "sub-0"))
        frame.addHeader(FrameHeader(k: Headers.DESTINATION.rawValue, v: topic))
        frame.addHeader(FrameHeader(k: Headers.ACK.rawValue, v: "client"))
        
        print(frame)
        
        let data = frame.toData()!
        
        underlyWebsocket.write(data: data)
        
        print(String(data: data, encoding: .utf8)!)
        
        return self
    }
    
    /**
     *
     */
    public func disconnect() {
        // send DISCONNECT with receipt header
        // wait for RECEIPT of previous sent recipt id
        // close the underlying websocket
    }
    
    /**
     *  start a new transaction.
     *   if
     */
    public func startTrx() {
        if (transaction == nil) {
            return
        }
        
        // check if connected
        // check if subscribed
        
        // start
        self.transaction = StompTran()
        
        // todo:
        // send begin fram
        
        var beginFrame = Frame(command: .BEGIN)
        send(frame: &beginFrame, using: .utf8)
    }
    
    /**
     *
     */
    public func commit() {
        
        if (transaction == nil) {
            var beginFrame = Frame(command: .COMMIT)
            send(frame: &beginFrame, using: .utf8)
        }
        
        transaction = nil
    }
    
    /**
     *
     */
    public func rollback() {
        
        if (transaction == nil) {
            var beginFrame = Frame(command: .ABORT)
            send(frame: &beginFrame, using: .utf8)
        }
        
        transaction = nil
    }
    
    /**
     * send messge using json
     */
    public func send(json msg: String, to uri: String, using encoding: String.Encoding? = .utf8, contentType: String = "application/json") {
        send(text: msg, to: uri, using: encoding, contentType: contentType)
    }
    
    /**
     *
     */
    public func send(json msg: StompMessage, to uri: String, using encoding: String.Encoding? = .utf8, contentType: String = "application/json") {
        send(json: msg.toJson(), to: uri, using: encoding, contentType: contentType)
    }
    
    /**
     *
     */
    public func send(text msg: StompMessage, to uri: String, using encoding: String.Encoding? = .utf8, contentType: String = "text/plain") {
        send(json: msg.toText(), to: uri, using: encoding, contentType: contentType)
    }
    
    /**
     *
     */
    public func send(text msg: String, to uri: String, using encoding: String.Encoding? = .utf8, contentType: String = "text/plain") {
        send(data: msg.data(using: encoding!)!, to: uri, using: encoding, contentType: contentType)
    }
    
    /**
     *
     */
    public func send(data: Data, to uri: String, using encoding: String.Encoding? = .utf8, contentType: String = "text/plain") {
        
        var frame = Frame.sendFrame(to: uri)
        
        frame.addHeader(FrameHeader(k: Headers.CONTENT_TYPE.rawValue, v: contentType))
        frame.addHeader(FrameHeader(k: Headers.CONTENT_LENGTH.rawValue, v: String(data.count)))
        frame.body.data = data
        
        send(frame: &frame)
    }
    
    /**
     * Transaction support
     */
    public func send(frame: inout Frame, using encoding: String.Encoding? = .utf8) {
        
        // support transaction
        if (transaction == nil) {
            frame.addHeader(FrameHeader(k: Headers.TRANSACTION.rawValue, v: transaction!.trxId))
        }
        
        let frameData = frame.toData(using: encoding!)!
        underlyWebsocket.write(data: frameData)
        print(String(data: frameData, encoding: encoding!)!)
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

/**
 * Message Protocol
 *
 *  Object conform this protocol can be
 */
public protocol StompMessage {
    func fromText(text data: String, using encoding: String.Encoding) throws -> StompMessage
    func fromJson(json data: String, using encoding: String.Encoding) throws -> StompMessage
    func toText () -> String
    func toJson() -> String
}
