//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 08/02/21.
//

public protocol HTTPClient {
    func get(from url: URL)
}

public class RemoteFeedLoader {
    //Feedloader's responsibility is not to know which URL it should use, instead it should be given by someone(the collaborator?), similarly the Client
    private var client: HTTPClient
    private var url: URL
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load() {
        client.get(from: url)
    }
}
