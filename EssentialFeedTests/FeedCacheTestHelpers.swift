//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 15/03/21.
//

import Foundation
import  EssentialFeed

func anyNSError() -> NSError{
    return NSError(domain: "An Error ", code: 0)
}

func uniqueImage() -> FeedImage {
    let url = URL(string: "a.url.com")!
    return FeedImage(id: UUID(), description: "anydesc", location: "anyloc", url: url)
}

func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
    let models = [uniqueImage(), uniqueImage()]
    let locals = models.map {
        LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
    }
    return (models, locals)
}


extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
