//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 11/02/21.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    var urlSession: URLSession
    
    init(session: URLSession = .shared) {
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
    
    func test_getFromURL_failsWithAnError() {
        URLProtocolStub.startInterceptingRequests()
        let url = URL(string: "a-url.com")!
        let error = NSError(domain: "Failed", code: 0)
        URLProtocolStub.stub(url: url, error: error)
        
        let sut = URLSessionHTTPClient()
        let exp = expectation(description: "Wait for Result to be completed")
        sut.get(url: url) { result in
            switch result {
            case let .Failure(actualError as NSError):
                XCTAssertEqual(error.domain, actualError.domain)
            default:
                XCTFail("Expected \(error) got data task)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
        URLProtocolStub.stopInterceptingRequests()
    }
    
    //MARK: - Helper Methods
    
    private class URLProtocolStub: URLProtocol {
        static var stub = [URL: StubResult]()
        
        struct StubResult {
            var error: Error?
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = [:]
        }
        
        static func stub( url: URL, error: Error? = nil) {
            stub[url] = StubResult(error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else {
                return false
            }
            return stub[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stub[url] else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
