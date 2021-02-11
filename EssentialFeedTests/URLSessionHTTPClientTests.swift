//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 11/02/21.
//

import XCTest

class URLSessionHTTPClient {
    var urlSession: URLSession
    
    init(session: URLSession) {
        self.urlSession = session
    }
    
    func get(url: URL) {
        urlSession.dataTask(with: url) { (_, _, _) in
            
        }
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test() {
        let url = URL(string: "a-url.com")!
        let session = URLSessionSpy()
        
        let sut = URLSessionHTTPClient(session: session)
        sut.get(url: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
            
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            
            return FakeURLSessionDataTask()
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {}
}
