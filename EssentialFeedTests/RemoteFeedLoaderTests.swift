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
    
    func test_loadTwice_createRequestDataFromURL() {
        let url = URL(string: "a.url.com")!
        let (sut, client) = makeSUT()
        
        sut.load()
        sut.load()
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_returnsConnectivityError() {
        let url = URL(string: "a.url.com")!
        let (sut, client) = makeSUT()
        client.error = NSError(domain: "Test", code: 0)
        var error: RemoteFeedLoader.Error?
        
        sut.load { err in
            error = err
        }
        
        XCTAssertEqual(error, .connectivity)
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "a.url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var errors = [Error]()
        var error: Error?
        
        func get(from url: URL, completion: @escaping (Error) -> Void) {
            if let e = error {
                completion(e)
            }
            requestedURLs.append(url)
//            errors.append(error)
        }
    }
}
