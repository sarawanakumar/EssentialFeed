//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 08/02/21.
//



public class RemoteFeedLoader: FeedLoader {
    //Feedloader's responsibility is not to know which URL it should use, instead it should be given by someone(the collaborator?), similarly the Client
    private var client: HTTPClient
    private var url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    public typealias Result = LoadFeedResult
    
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] httpClientResult in
            guard self != nil else { return }
            
            switch httpClientResult {
            case .Success(let response, let data):
                completion(FeedItemsMapper.map(data: data, response: response)) //capture self,possible retain cycle
            case .Failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
