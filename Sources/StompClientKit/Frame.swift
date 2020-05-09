//
//  Frame.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation

/**
 * StompFrame Struct
 *
 * A stomp frame is consist of Comman, Headers, and an optional body.
 *
 */
public struct Frame {
    
    /// Command ID
    ///
    private var cid : CommandID = .CONNECT
    
    /// Headers
    private var headers: [FrameHeader] = []
    
    /// Frame Body
    public var body: Data = Data()
    
    
    /// Constructor
    ///
    /// - Parameter id: mandatory command id.
    public init(command id: CommandID ) {
        cid = id
    }
    
    
    /// Add Header
    ///
    /// - Parameter header: new Header
    public mutating func addHeader(_ header: FrameHeader) {
        self.headers.append(header)
    }
    
    /// Payload
    /// Computed Property that builds a payload of the frame for sending
    ///
    public var payload : Data {
        var commandAndHeaders = ""
        commandAndHeaders += cid.rawValue
        commandAndHeaders.append(ControlChars.LF.rawValue)
        
        for h in headers {
            commandAndHeaders += h.text()
            commandAndHeaders.append(ControlChars.LF.rawValue)
        }
        
        commandAndHeaders.append(ControlChars.LF.rawValue)

        // payload
        var pl = Data()
        pl.append(commandAndHeaders.data(using: .utf8)!)
        pl.append(0)
        
        return pl
        
    }
    
    /// Determine if it is a CONNECT header
    ///
    var isConnected : Bool {
        return (cid == CommandID.CONNECTED)
    }
    
    /// Determine if it is a CONNECT header
    var isReceipt : Bool {
        return (cid == CommandID.RECEIPT)
    }
    
    /// Determine if it is a CONNECT header
    var isMessage : Bool {
        return (cid == CommandID.MESSAGE)
    }
    
    /// Determine if it is a CONNECT header
    var isError : Bool {
        return (cid == CommandID.ERROR)
    }
    
    /// Build a CONNECT Frame.
    ///
    /// - Parameter versions: accept versions
    /// - Returns: a Frame with a CONNECT command.
    static public func connectFrame(versions: String = "1.2,1.1") -> Frame {
        var f = Frame(command: .CONNECT)
        f.headers.append(FrameHeader(k: Headers.ACCEPT_VERSION.rawValue, v: versions))
        return f
    }
    
    /// Build a CONNECTED Frame.
    /// - Returns: a Frame with a CONNECTED Command.
    static public func connectedFrame() -> Frame {
        let f = Frame(command: .CONNECTED)

        return f
    }
    
    /// Build a SUBSCRIBE Frame
    ///
    /// - Returns: a frame with a SUBSCRIBE Command.
    static public func subscribeFrame() -> Frame {
        let f = Frame(command: .SUBSCRIBE)

        return f
    }
    
    /// Build a SEND Frame
    ///
    /// - Returns: a frame for SEND Command
    static public func sendFrame(to destination: String) -> Frame {
        var frame = Frame(command: .SEND)
        frame.addHeader(FrameHeader(k: Headers.DESTINATION.rawValue, v: destination))
        return frame
    }
}

/**
 * FrameHeader
 */
public struct FrameHeader {
    var key: String
    var value: String
    
    /// Constructor
    ///
    public init(k: String, v:String) {
        self.key = k
        self.value = v
    }
    
    /// Text that represents the header.
    public func text() -> String {
        return key + String(ControlChars.COLON.rawValue) + value
    }
}

/**
 * Headers ENUM.
 */
public enum Headers: String {
    case ACCEPT_VERSION = "accept-version"
    case HEART_BEATE = "heart-beat"
    case VERSION = "version"
    case HOST = "host"
    case CONTENT_TYPE = "content-type"
    case CONTENT_LENGTH = "content-length"
    case ID = "id"
    case DESTINATION = "destination"
    case ACK = "ack"
    case TRANSACTION = "transaction"
    
}

/**
 *  A Frame Parser
 */
class FrameParser {
    private var stompVersion : StompVersion = .UNKNOWN
    
    public var resultFrame : Frame?
    
    ///
    ///
    public init(accepted version: StompVersion) {
        self.stompVersion = version
    }
    
    /// Binary data parsing
    ///
    /// - Parameter data: frame data, includes command and headers and body.
    public func parse(data: Data) {
        var frame : Frame? = nil
        
        var command = ""
        var headers : [FrameHeader] = []
        
        var stage = ParseStage.command
        var key = "", value = ""
        var body = Data()
        var bodyLength = 0
        var contentLengthValue = 0
        
        for (_, ch) in data.enumerated() {
            switch stage {
            case .command:
                if (ch == ControlChars.CR.rawValue.asciiValue) {
                    continue
                } else if (ch == ControlChars.LF.rawValue.asciiValue) {
                    frame = constructFrame(command)
                    stage = .headerKey
                } else {
                    command.append(Character(UnicodeScalar(ch)))
                }
            case .headerKey:
                if (ch == ControlChars.CR.rawValue.asciiValue) {
                    continue
                } else if (ch == ControlChars.LF.rawValue.asciiValue) {
                    stage = .body
                } else if (ch == ControlChars.COLON.rawValue.asciiValue) {
                    stage = .headerValue
                } else {
                    key.append(Character(UnicodeScalar(ch)))
                }
            case .headerValue:
                if (ch == ControlChars.CR.rawValue.asciiValue) {
                    continue
                } else if (ch == ControlChars.LF.rawValue.asciiValue) {
                    let header = FrameHeader(k: key, v: value)
                    if (frame != nil) {
                        frame!.addHeader(header)
                        if (header.key=="content-length") {
                            contentLengthValue = Int(header.value)!
                            // TODO: Max Content-Length validate
                        }
                    }
                    headers.append(header)
                    key = ""
                    value = ""
                    stage = .headerKey
                } else {
                    value.append(Character(UnicodeScalar(ch)))
                }
            case .body:
                if (ch == ControlChars.NULL.rawValue.asciiValue) {
                    stage = .end
                } else {
                    body.append(ch)
                    bodyLength += 1
                }
                
                if (contentLengthValue == bodyLength) {
                    stage = .end
                }
                
            case .end:
                if (ch != ControlChars.NULL.rawValue.asciiValue) {
                    // Handle abnormall data
                }
            }
        }
        
        if (frame == nil) {
            resultFrame = nil
        } else {
            frame!.body = body
            resultFrame = frame
        }
    }
    
    
    /// Parsing Frame as Text
    ///
    /// - Parameter text: frame text
    public func parse(text: String) {
        var frame : Frame? = nil
        
        var command = ""
        var headers : [FrameHeader] = []
        
        var stage = ParseStage.command
        var key = "", value = ""
        var body = "", bodyLength = 0
        var contentLengthValue = 0
        
        for (_, ch) in text.enumerated() {
            switch stage {
            case .command:
                if (ch == ControlChars.CR.rawValue) {
                    continue
                } else if (ch == ControlChars.LF.rawValue) {
                    frame = constructFrame(command)
                    stage = .headerKey
                } else {
                    command.append(ch)
                }
            case .headerKey:
                if (ch == ControlChars.CR.rawValue) {
                    continue
                } else if (ch == ControlChars.LF.rawValue) {
                    stage = .body
                } else if (ch == ControlChars.COLON.rawValue) {
                    stage = .headerValue
                } else {
                    key.append(ch)
                }
            case .headerValue:
                if (ch == ControlChars.CR.rawValue) {
                    continue
                } else if (ch == ControlChars.LF.rawValue) {
                    let header = FrameHeader(k: key, v: value)
                    if (frame != nil) {
                        frame!.addHeader(header)
                        if (header.key=="content-length") {
                            contentLengthValue = Int(header.value)!
                            // TODO: Max Content-Length validate
                        }
                    }
                    headers.append(header)
                    key = ""
                    value = ""
                    stage = .headerKey
                } else {
                    value.append(ch)
                }
            case .body:
                if (ch == ControlChars.NULL.rawValue) {
                    stage = .end
                } else {
                    body.append(ch)
                    bodyLength += 1
                }
                if (contentLengthValue == bodyLength) {
                    stage = .end
                }
            case .end:
                if (ch != ControlChars.NULL.rawValue) {
                    // Handle abnormall data
                }
                break
            }
        }
        
        if (frame == nil) {
            resultFrame = nil
        } else {
            frame!.body = body.data(using: .utf8)!
            resultFrame = frame
        }
    }
    
    /// Construct a template frame.
    private func constructFrame(_ command: String) -> Frame? {
        if ("CONNECTED" == command) {
            return  Frame(command: CommandID.CONNECTED)
        } else if ("MESSAGE" == command) {
            return Frame(command: CommandID.MESSAGE)
        } else if ("RECEIPT" == command) {
            return Frame(command: CommandID.RECEIPT)
        } else if ("ERROR" == command) {
            return Frame(command: CommandID.ERROR)
        } else {
            return nil
        }
    }
}

/**
 * Enum that repersents Frame parsing stage.
 */
enum ParseStage {
    case command
    case headerKey
    case headerValue
    case body
    case end
}
