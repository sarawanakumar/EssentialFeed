//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 07/02/21.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
