//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 08/02/21.
//

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public enum HTTPClientResult {
    case Success(HTTPURLResponse, Data)
    case Failure(Error)
}

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
                if response.statusCode == 200,
                   let root = try? JSONDecoder().decode(Root.self, from: data) {
                    completion(.success(root.items.map({$0.item})))
                } else {
                    completion(.failure(.invalidData))
                }
            case .Failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

private struct Root: Decodable {
    let items: [Item]
}

private struct Item: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
    
    var item: FeedItem {
        return FeedItem(
            id: id,
            description: description,
            location: location,
            imageURL: image
        )
    }
}
