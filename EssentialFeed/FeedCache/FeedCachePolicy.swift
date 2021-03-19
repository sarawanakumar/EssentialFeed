//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 20/03/21.
//

import Foundation

internal final class FeedCachePolicy {
    private init() {}
    private static let cal = Calendar(identifier: .gregorian)
    private static var maxCacheAgeInDays: Int {
        return 7
    }
    
    internal static func validate(_ timestamp: Date, against date: Date) -> Bool {
        guard let maxAge = cal.date(byAdding: .day, value: maxCacheAgeInDays, to: timestamp) else { return false }
        return date < maxAge
    }
}
