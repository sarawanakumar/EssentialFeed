//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 08/02/21.
//



public class RemoteFeedLoader {
    //Feedloader's responsibility is not to know which URL it should use, instead it should be given by someone(the collaborator?), similarly the Client
    private var client: HTTPClient
    private var url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { httpClientResult in
            switch httpClientResult {
            case .Success(let response, let data):
                completion(FeedItemsMapper.map(data: data, response: response)) //capture self,possible retain cycle
            case .Failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
