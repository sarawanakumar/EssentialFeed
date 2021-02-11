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
        urlSession.dataTask(with: url) { (_, _, _) in }
            .resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {

    func test_getFromURL_receivedThePassedURL() {
        let url = URL(string: "a-url.com")!
        let session = URLSessionSpy()
        
        let sut = URLSessionHTTPClient(session: session)
        sut.get(url: url)
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    func test_getFromURL_resumesTheDataTask() {
        //The test are testing exactly the implementation of the URLSession/DataTask apis, whihc is not ideal
        let url = URL(string: "a-url.com")!
        let session = URLSessionSpy()
        let taskSpy = URLSessionDataTaskSpy()
        session.stub(url, taskSpy)
        
        let sut = URLSessionHTTPClient(session: session)
        sut.get(url: url)
        
        XCTAssertEqual(taskSpy.resumeCallCount, 1)
    }
    
    private class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        var stub = [URL: URLSessionDataTask]()
        
        func stub(_ url: URL, _ task: URLSessionDataTask) {
            stub[url] = task
        }
            
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(url)
            
            return stub[url] ?? FakeURLSessionDataTask()
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {}
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }
}
