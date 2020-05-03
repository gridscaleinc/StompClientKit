//
//  Subscription.swift
//  
//
//  Created by gridscale on 2020/05/03.
//

import Foundation


struct Subscription {
    public var subId = generateSubId()
    private static var subscriptionSequence = 1
    
    /**
     *
     */
    private func generateSubId() -> String {
        return "sub-" + (subscriptionSequence++)
    }
}
