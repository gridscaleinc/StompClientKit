//
//  File.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation

/**
 * Enum of Stomp Command ID
 *  Since Stomp 1.2
 */
public enum CommandID: String {
    
    case STOMP
    case CONNECT
    case DISCONNECT
    case CONNECTED
    case SUBSCRIBE
    case UNSUBSCRIBE
    case SEND
    case ACK
    case NACK
    case ABORT
    case BEGIN
    case COMMIT
    case MESSAGE
    case RECEIPT
    case ERROR
}
