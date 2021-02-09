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
        
        sut.load { error in }
        
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
//      Spy instead of a mock (do later vs early 9the expectations0)
        expect(sut, completeWith: .connectivity) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_returnsNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let errorCodes = [199, 201, 300, 400, 500]
        errorCodes.enumerated()
            .forEach { (idx, code) in
                expect(sut, completeWith: .invalidData) {
                    client.complete(withStatusCode: code, at: idx)
                }
        }
    }
    
    func test_deliversErrorWith200AndInvalidJson() {
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: .invalidData) {
            let invalidJSON = Data("invalidjson".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    //MARK: - Helpers
    
    private func expect(
        _ sut: RemoteFeedLoader,
        completeWith error: RemoteFeedLoader.Error,
        action: ()->Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var capturedErrors = [RemoteFeedLoader.Error]()
        sut.load { capturedErrors.append($0) }
        
        action()

        XCTAssertEqual(capturedErrors, [error], file: file, line: line)
    }
     
    private func makeSUT(url: URL = URL(string: "a.url.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        private var messages = [(url: URL, completion: (HTTPClientResult)->Void)]()
        
        var requestedURLs: [URL] {
            return messages.map {$0.url}
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url,completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.Failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil
            )!
            messages[index].completion(.Success(response, data))
        }
    }
}
