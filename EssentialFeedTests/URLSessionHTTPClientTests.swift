//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 11/02/21.
//

import XCTest
import EssentialFeed

protocol HTTPSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask
}

protocol HTTPSessionTask {
    func resume()
}

class URLSessionHTTPClient {
    var urlSession: HTTPSession
    
    init(session: HTTPSession) {
        self.urlSession = session
    }
    
    func get(url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        let task = urlSession.dataTask(with: url) { (_, _, error) in
            if let error = error {
                completion(.Failure(error))
            }
        }
        task.resume()
    }
}

class URLSessionHTTPClientTests: XCTestCase {
    
    func test_getFromURL_resumesTheDataTask() {
        //The test are testing exactly the implementation of the URLSession/DataTask apis, whihc is not ideal
        let url = URL(string: "a-url.com")!
        let session = HTTPSessionSpy()
        let taskSpy = HTTPSessionTaskSpy()
        session.stub(url: url, task: taskSpy)
        
        let sut = URLSessionHTTPClient(session: session)
        sut.get(url: url) { _ in
        }
        
        XCTAssertEqual(taskSpy.resumeCallCount, 1)
    }
    
    func test_getFromURL_failsWithAnError() {
        let url = URL(string: "a-url.com")!
        let error = NSError(domain: "Failed", code: 0)
        let session = HTTPSessionSpy()
        session.stub(url: url, error: error)
        
        let sut = URLSessionHTTPClient(session: session)
        let exp = expectation(description: "Wait for Result to be completed")
        sut.get(url: url) { result in
            switch result {
            case let .Failure(actualError as NSError):
                XCTAssertEqual(error, actualError)
            default:
                XCTFail("Expected \(error) got data task)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helper Methods
    private class HTTPSessionSpy: HTTPSession {
        var stub = [URL: StubResult]()
        
        struct StubResult {
            var dataTask: HTTPSessionTask
            var error: Error?
        }
        
        func stub( url: URL, task: HTTPSessionTask = FakeHTTPSessionTask(), error: Error? = nil) {
            stub[url] = StubResult(dataTask: task, error: error)
        }
            
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPSessionTask {
            guard let stub = stub[url] else {
                fatalError("Could not find stub for the url \(url)")
            }
            completionHandler(nil, nil, stub.error)
            
            return stub.dataTask
        }
    }
    
    private class FakeHTTPSessionTask: HTTPSessionTask {
        func resume() {}
    }
    
    private class HTTPSessionTaskSpy: HTTPSessionTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
