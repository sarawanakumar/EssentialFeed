//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 08/02/21.
//

import XCTest
@testable import EssentialFeed

class RemoteFeedLoader {
    func load() {
        HTTPClient.shared.requestedURL = URL(string: "A.URL>COM")
    }
}

class HTTPClient {
    static let shared = HTTPClient()
    var requestedURL: URL?
}

class RemoteFeedLoaderTests: XCTestCase {

    
    func test_init_doesntRequestDataFromURL() {
        let client = HTTPClient()
        _ = RemoteFeedLoader()
        
        
        XCTAssertNil(client.requestedURL)
    }

    func test_load_createRequestDataFromURL() {
        let client = HTTPClient()
        let sut = RemoteFeedLoader()
        
        sut.load()
        
        XCTAssertNil(client.requestedURL)
    }
}
