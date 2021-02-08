//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 08/02/21.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesntRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }

    func test_load_createRequestDataFromURL() {
        let url = URL(string: "a.url.com")!
        let (sut, client) = makeSUT()
        
        sut.load()
        
        XCTAssertEqual([url], client.requestedURLs)
    }
    
    func test_load_createRequestDataFromURLTwice() {
        let (sut, client) = makeSUT()
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs.count, 2)
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "a.url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        
        func get(from url: URL) {
            requestedURLs.append(url)
        }
    }
}
