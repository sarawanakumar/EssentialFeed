//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 08/02/21.
//

import XCTest
@testable import EssentialFeed

class RemoteFeedLoader {
    //Feedloader's responsibility is not to know which URL it should use, instead it should be given by someone(the collaborator?), similarly the Client
    var client: HTTPClient
    var url: URL
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesntRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }

    func test_load_createRequestDataFromURL() {
        let url = URL(string: "a.url.com")!
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertEqual(url, client.requestedURL)
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "a.url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            requestedURL = url
        }
    }
}
