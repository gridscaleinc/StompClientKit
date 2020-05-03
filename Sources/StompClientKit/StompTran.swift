//
//  StompTran.swift
//  
//
//  Created by gridscale on 2020/05/03.
//

import Foundation

/**
 *
 */
public struct StompTran {
    public var trxId = generateTrxId()
    
    private static var tranSequence = 1
    
    /**
     *
     */
    private static func generateTrxId() -> String {
        tranSequence += 1
        return "trx-" + String(tranSequence) + "-" + String(Int.random(in: (1000...9999)))
    }

}
