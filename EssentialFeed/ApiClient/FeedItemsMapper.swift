//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 10/02/21.
//

import Foundation

internal final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    static var OK_200 = 200
    
    
    internal static func map(data: Data, response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == OK_200,
              let root = try? JSONDecoder().decode(Root.self, from: data) else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
