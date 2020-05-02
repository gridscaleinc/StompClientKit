//
//  File.swift
//  
//
//  Created by gridscale on 2020/04/25.
//

import Foundation

public struct Frame {
    
    private var cid : CommandID = .CONNECT
    private var headers: [FrameHeader] = []
    public var body: FrameBody = FrameBody()
    
    //
    public init(command id: CommandID ) {
        cid = id
    }
    
    //
    public mutating func addHeader(_ header: FrameHeader) {
        self.headers.append(header)
    }
    
    //
    public func toData(using encoding: String.Encoding = .utf8) -> Data? {
        var s = ""
        s += cid.rawValue
        s.append(ControlChars.LF.rawValue)
        
        for h in headers {
            s += h.text()
            s.append(ControlChars.LF.rawValue)
        }
        
        s.append(ControlChars.LF.rawValue)
        s += body.text
        s.append(ControlChars.NULL.rawValue)
        
        return s.data(using: encoding)
        
    }
    
    var isConnected : Bool {
        return (cid == CommandID.CONNECTED)
    }
    
    var isReceipt : Bool {
        return (cid == CommandID.RECEIPT)
    }
    
    
    var isMessage : Bool {
        return (cid == CommandID.MESSAGE)
    }
    
    var isError : Bool {
        return (cid == CommandID.ERROR)
    }
    
    //
    static public func connectFrame(versions: String = "1.2,1.1") -> Frame {
        var f = Frame(command: .CONNECT)
        f.headers.append(FrameHeader(k: Headers.ACCEPT_VERSION.rawValue, v: versions))
        return f;
    }
    
    static public func connectedFrame() -> Frame {
        let f = Frame(command: .CONNECTED)

        return f;
    }
    
    static public func subscribeFrame() -> Frame {
        let f = Frame(command: .SUBSCRIBE)

        return f;
    }
    
    static public func sendFrame(to destination: String) -> Frame {
        var frame = Frame(command: .SEND)
        frame.addHeader(FrameHeader(k: Headers.DESTINATION.rawValue, v: destination))
        return frame
    }
}

public struct FrameHeader {
    var key: String
    var value: String
    
    //
    //
    public init(k: String, v:String) {
        self.key = k
        self.value = v
    }
    
    //
    public func text() -> String {
        return key + String(ControlChars.COLON.rawValue) + value
    }
}

//
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
    
}


public struct FrameBody {
    
    private var _data = Data()
    
    public var data : Data {
        get {
            return _data
        }
        set {
            _data = newValue
        }
    }
    
    private var encoding = String.Encoding.utf8
    
    //
    public var text : String {
        let t = String(data: data, encoding: encoding)
        if (t == nil) {
            return ""
        } else {
            return t!
        }
    }
}

//
public class FrameParser {
    private var stompVersion : StompVersions = .UNKNOWN
    
    public var resultFrame : Frame?
    
    //
    public init(as version: StompVersions) {
        self.stompVersion = version
    }
    
    //
    public func parse(text: String) {
        var frame : Frame? = nil
        
        var command = ""
        var headers : [FrameHeader] = []
        
        var stage = ParseStage.command
        var key = "", value = ""
        var body = ""
        
        for (n,ch) in text.enumerated() {
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
                }
            case .end:
                break
            }
        }
        
        if (frame == nil) {
            resultFrame = nil
        } else {
            frame!.body.data = body.data(using: .utf8)!
            resultFrame = frame
        }
    }
    
    //
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

enum ParseStage {
    case command
    case headerKey
    case headerValue
    case body
    case end
    
}
