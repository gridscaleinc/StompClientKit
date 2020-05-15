//
//  StompClient.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation
import Combine
import UIKit

//
public typealias MessageHandler = (_ message : Frame) -> Void

/**
 * Stomp Client over Websocket.
 *
 *  Connect to websocket, subscribe to topic,
 *  send and receive message to / from server.
 */
public class StompClient: WebSocketChannelDelegate {
    
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
    private var version = StompVersion.UNKNOWN
    
    // STOMP Heart beat value. 0 means not send.
    private var heartbeat = 0
    
    // On Connected Handling callback hook.
    private var onStompConnected : (_ client: StompClient) -> Void = {_ in }
    
    // intilize the underlying websocket object.
    // at this point, the websocket had not connected to server yet.
    public init(endpoint url : String) {
        underlyWebsocket = StarscreamWSChannel(url: url)
        underlyWebsocket.delegate = self
    }
    
    /**
     *
     */
    public init(over channel: WebSocketChannel) {
        underlyWebsocket = channel
        underlyWebsocket.delegate = self
    }
    
    /**
     * to Conform WebSocketChannelDelegate
     */
    public func onChannelConnected () {
        var command = Frame.connectFrame(versions: "1.2,1.1")
        command.addHeader(FrameHeader(k: Headers.HOST.rawValue, v: "192.168.11.5"))
        let data = command.payload

        // TODO : Change to  write text
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
        handleRecevedText(text: text)
    }
    
    public func onBinaryData(received data: Data) {
        // handle stomp frame
        handleRecevedData(data: data)
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
    public func startConnect (onConnected handler: @escaping (_ client: StompClient) -> Void) -> Self {
        
        self.onStompConnected = handler
        underlyWebsocket.connect()
        
        return self
    }
    
    /**
     *
     */
    public func subscribe(to topic : String) -> Subscription {
        
        var frame = Frame.subscribeFrame()
        
        var subscription = Subscription()
        subscriptions[subscription.subId] = subscription
        
        // TODO generate id
        frame.addHeader(FrameHeader(k: Headers.ID.rawValue, v: "sub-0"))
        frame.addHeader(FrameHeader(k: Headers.DESTINATION.rawValue, v: topic))
        frame.addHeader(FrameHeader(k: Headers.ACK.rawValue, v: "client"))
        
        print(frame)
        
        let data = frame.payload
        
        underlyWebsocket.write(data: data)
        
        print(String(data: data, encoding: .utf8)!)
        
        return subscription
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
        send(frame: &beginFrame)
    }
    
    /**
     *
     */
    public func commit() {
        
        if (transaction == nil) {
            var beginFrame = Frame(command: .COMMIT)
            send(frame: &beginFrame)
        }
        
        transaction = nil
    }
    
    /**
     *
     */
    public func rollback() {
        
        if (transaction == nil) {
            var beginFrame = Frame(command: .ABORT)
            send(frame: &beginFrame)
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
        send(text: msg.toText(), to: uri, using: encoding, contentType: contentType)
    }
    
    /**
     *
     */
    public func send(text msg: String, to uri: String, using encoding: String.Encoding? = .utf8, contentType: String = "text/plain") {
        send(data: msg.data(using: encoding!)!, to: uri, contentType: contentType)
    }
    
    /**
     *
     */
    public func send(image data: UIImage, to uri: String) {
        if (data.pngData() == nil) {
            return
        }
        
        send(data: data.pngData()!, to: uri, contentType: "image/png")
        
    }
    
    /**
     *
     */
    public func send(data: Data, to uri: String, contentType: String = "text/plain") {
        
        var frame = Frame.sendFrame(to: uri)

        frame.addHeader(FrameHeader(k: Headers.CONTENT_TYPE.rawValue, v: contentType))
        frame.addHeader(FrameHeader(k: Headers.CONTENT_LENGTH.rawValue, v: String(data.count)))
        frame.body = data
        
        send(frame: &frame)
    }
    
    /**
     * Transaction support
     */
    public func send(frame: inout Frame) {
        
        // support transaction
        if (transaction != nil) {
            frame.addHeader(FrameHeader(k: Headers.TRANSACTION.rawValue, v: transaction!.trxId))
        }
        
        let frameData = frame.payload
        underlyWebsocket.write(data: frameData)
    }
    
    /// Binary Data Handling
    /// - Parameter data: data received from websocket channel
    func handleRecevedData(data: Data) {
        // check
        
        let parser = FrameParser(accepted: .VER1_2)
        parser.parse(data: data)
        
        let frame = parser.resultFrame
        
        if (frame == nil) {
            return
        }
        
        handleReceivedFrame(frame: frame!)
    }
    
    /// Handle Frame text from server, update client status or call message handler
    /// according to the content of the frame.
    /// - Parameter text: <#text description#>
    func handleRecevedText(text: String) {
        // check
        
        let parser = FrameParser(accepted: .VER1_2)
        parser.parse(text: text)
        
        let frame = parser.resultFrame
        
        if (frame == nil) {
            return
        }
        
        handleReceivedFrame(frame: frame!)
        
    }
    
    /// Handling received frame
    ///
    /// - Parameter frame: received frame
    private func handleReceivedFrame(frame: Frame) {
        // if CONNECTED
        if (frame.isConnected) {
            status = .CONNECTED
            // retrieve heart beat
            // retrieve protocol version
            
            // call back to onConnected function
            _ = onStompConnected(self)
            
        } else if ( frame.isMessage) {
        // if MESSAGE
            let subId = frame.subscriptionId
            if (subId != nil) {
                let subscription = subscriptions[subId!]
                subscription?.messageHandler(frame)
            }
            
        } else if ( frame.isReceipt) {
        // if RECEIPT
            
        } else if ( frame.isError) {
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
