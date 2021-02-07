//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 07/02/21.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case error(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
