//
//  Subscription.swift
//  
//
//  Created by gridscale on 2020/05/03.
//

import Foundation


public struct Subscription {
    public var subId = generateSubId()
    private static var subscriptionSequence = 1
    
    /**
     *
     */
    private static func generateSubId() -> String {
        subscriptionSequence += 1
        return "sub-" + (String(subscriptionSequence))
    }
}
