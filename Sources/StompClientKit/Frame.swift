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
    private var body: FrameBody = FrameBody()
    
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
        s += ControlChars.LF.rawValue
        
        for h in headers {
            s += h.text() + ControlChars.LF.rawValue
        }
        
        s += ControlChars.LF.rawValue
        s += body.text
        s += ControlChars.NULL.rawValue
        
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
        return key + ControlChars.COLON.rawValue + value
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
    
}


public struct FrameBody {
    private var data : Data = Data()
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
        
    }
}
