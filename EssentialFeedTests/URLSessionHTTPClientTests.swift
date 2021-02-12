//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 11/02/21.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClient {
    struct UnexpectedErrorRepresentation: Error {}
    
    var urlSession: URLSession
    
    init(session: URLSession = .shared) {
        self.urlSession = session
    }
    
    func get(url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        let task = urlSession.dataTask(with: url) { (_, _, error) in
            if let error = error {
                completion(.Failure(error))
            } else {
                completion(.Failure(UnexpectedErrorRepresentation()))
            }
        }
        task.resume()
    }
}

/**
 * A test must test only one aspect of the whole feature.
 * However, in the example 'test_getFromURL_failsWithAnError'
 * The test checks, if the url passed is valid and for that url, shall the error gets returned?
 * Which is not ideal.
 * So, split or write a separate test to verify the URL is valid /received by the stub correctly
 * and another test to test the validity of the code (error/success data)
 *
 *PTR:
 *1.We need to have accurate assertions stating what is failing. which helps in knowing why test is failing? adds value to the test
 *2.We focus on handling various error/success cases in one test and validating url in another
 */
class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_ExecutesURLWithGETRequest() {
        let url = anyURL()
        let exp = expectation(description: "Wait for the completion to execute")
        
        URLProtocolStub.observeRequest { urlRequest in
            XCTAssertEqual(urlRequest.url, url)
            XCTAssertEqual(urlRequest.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(url: url) { (_) in }
        
        wait(for: [exp], timeout: 1.0)
        
    }
    
    func test_getFromURL_failsWithAnError() {
        
        let error = NSError(domain: "Failed", code: 0)
        URLProtocolStub.stub(data: nil, response: nil, error: error)
        
        let exp = expectation(description: "Wait for Result to be completed")
        makeSUT().get(url: anyURL()) { result in
            switch result {
            case let .Failure(actualError as NSError):
                XCTAssertEqual(error.domain, actualError.domain)
            default:
                XCTFail("Expected \(error) got data task)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_getFromURL_failsWhenAllParamsReceivedAreNil() {
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        
        let exp = expectation(description: "Wait for Result to be completed")
        makeSUT().get(url: anyURL()) { result in
            switch result {
            case .Failure:
                break
            default:
                XCTFail("Assertion failure")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: - Helper Methods
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        
        return sut
    }
    
    func anyURL() -> URL {
        return URL(string: "a-url.com")!
    }
    
    private class URLProtocolStub: URLProtocol {
        static var stub: StubResult?
        static var requestObserver: ((URLRequest) -> Void)?
        
        struct StubResult {
            var data: Data?
            var response: HTTPURLResponse?
            var error: Error?
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            requestObserver = observer
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        static func stub(data: Data?, response: HTTPURLResponse?, error: Error?) {
            stub = StubResult(error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
