//
//  StompClient.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation

//
public typealias MessageHandler = (_ frame : Frame) -> Any

/**
 * Stomp Client over Websocket.
 *
 *  Connect to websocket, subscribe to topic,
 *  send and receive message to / from server.
 */
public class StompClient: WebSocketChannelDelegate {
    
    public var messageHandler : MessageHandler = {_ in }
    private var underlyWebsocket : WebSocketChannel
    
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
    private var onStompConnected : (_ client: StompClient) -> Any = {_ in }
    
    // intilize the underlying websocket object.
    // at this point, the websocket had not connected to server yet.
    public init(endpoint url : String) {
        underlyWebsocket = StarscreamWSChannel(url: url)
    }
    
    /**
     *
     */
    public init(over channel: WebSocketChannel) {
        underlyWebsocket = channel
    }
    
    /**
     * to Conform WebSocketChannelDelegate
     */
    public func onChannelConnected () {
        var command = Frame.connectFrame(versions: "1.2,1.1")
        command.addHeader(FrameHeader(k: Headers.HOST.rawValue, v: "192.168.11.5"))
        let data = command.toData()!

        underlyWebsocket.write(data: data)

        print(String(data: data, encoding: .utf8)!)
    }
    
    /**
     *
     */
    public func onChannelDisConnected() {
        
    }
    
    /**
     *
     */
    public func onText(received text: String) {
        // handle stomp frame
        handleFrame(text: text)
    }
    
    /**
     *
     */
    public func onChannelError(_ error: Error) {
        //
    }
    
    
    /**
     * Start to connect to websocket server.
     *
     */
    public func startConnect (onConnected handler : @escaping (_ client: StompClient) -> Any) {
        self.onStompConnected = handler
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
        if (transaction != nil) {
            frame.addHeader(FrameHeader(k: Headers.TRANSACTION.rawValue, v: transaction!.trxId))
        }
        
        let frameData = frame.toData(using: encoding!)!
        underlyWebsocket.write(data: frameData)
        print(String(data: frameData, encoding: encoding!)!)
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
            _ = onStompConnected(self)
            
        } else if ( frame!.isMessage) {
        // if MESSAGE
            _ = messageHandler(frame!)
            
        } else if ( frame!.isReceipt) {
        // if RECEIPT
            
        } else if ( frame!.isError) {
        // if ERROR
            
        } else {
            // exception
        }
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
