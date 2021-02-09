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
        
        sut.load{ error in }
        
        XCTAssertEqual([url], client.requestedURLs)
    }
    
    func test_loadTwice_createRequestDataFromURL() {
        let url = URL(string: "a.url.com")!
        let (sut, client) = makeSUT()
        
        sut.load { error in }
        sut.load { error in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_returnsConnectivityError() {
        let (sut, client) = makeSUT()
//        client.error = NSError(domain: "Test", code: 0)//This is stub, which can act as spy
        var capturedErrors = [RemoteFeedLoader.Error]()
        
        sut.load { capturedErrors.append($0) }
        
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
        
        XCTAssertEqual(capturedErrors, [.connectivity])
    }
    
    //MARK: - Helpers
    private func makeSUT(url: URL = URL(string: "a.url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (Error)->Void)]()
        
        var requestedURLs: [URL] {
            return messages.map {$0.url}
        }

        func get(from url: URL, completion: @escaping (Error) -> Void) {
            messages.append((url,completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(error)
        }
    }
}
