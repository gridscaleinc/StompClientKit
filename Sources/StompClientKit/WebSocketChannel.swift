//
//  WebSocketChannel.swift
//  
//
//  Created by gridscale on 2020/05/01.
//

import Foundation

//
public protocol WebSocketChannel: class {
    init(url : String)
    init(url : URLRequest)
    
    func connect()
    func disconnect(closeCode: UInt16)
    func send(data: Data)
    var receiver: DataReceiver { get set}
}

//
public typealias DataReceiver = (_ data: Data, _ channel: WebSocketChannel) -> Any
