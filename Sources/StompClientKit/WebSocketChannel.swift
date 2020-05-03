//
//  WebSocketChannel.swift
//  
//
//  Created by gridscale on 2020/05/01.
//

import Foundation

/**
 * StompClientKit uses Starscream as the default Websocket backbone. However, it is better not to lock on Starscream,
 * so use this class to weaken your dependence on Starscream. By implementing this protocol, developers can use
 * another Websocket library. Future versions of StompClientKit may add new Websocket libraries.
 */
public protocol WebSocketChannel: class {
    
    /**
     * Build a new channel using a Websocket URL .
     */
    init(url : String)
    
    /**
     * Build a new channel using a Websocket URL Request.
     */
    init(url : URLRequest)
    
    /**
     * Start to connect to WebSocket Server.
     *
     * Note: The connection will not be established until it receives a CONNECTED response from the Websocket server.
     */
    func connect()
    
    /**
     * Disconnect from the websocket server.
     * Usually, the method is called from StompClient, so if you call it directly,
     * there is a risk that the transaction control and message exchange may end halfway.
     */
    func disconnect(closeCode: UInt16)
    
    /**
     * Sending Data to websocket server.
     */
    func send(data: Data)
    
    /**
     * Property
     * Handler of received data from websocket message channel.
     */
    var receiver: DataReceiver { get set}
}

/**
 *
 */
public typealias DataReceiver = (_ data: Data, _ channel: WebSocketChannel) -> Any
