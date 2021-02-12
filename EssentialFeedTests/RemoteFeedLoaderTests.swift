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
        expect(sut, completeWith: failure(.connectivity)) {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        }
    }
    
    func test_load_returnsNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let errorCodes = [199, 201, 300, 400, 500]
        errorCodes.enumerated()
            .forEach { (idx, code) in
                expect(sut, completeWith: failure(.invalidData)) {
                    let json = makeItemsJson([])
                    client.complete(withStatusCode: code, data: Data(json), at: idx)
                }
        }
    }
    
    func test_deliversErrorWith200AndInvalidJson() {
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: failure(.invalidData)) {
            let invalidJSON = Data("invalidjson".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_deliversNoItemsOnHttp200WithEmptyJSONList() {
        let (sut, client) = makeSUT()

        expect(sut, completeWith: .success([])) {
            let emptyListJSON = makeItemsJson([])
            client.complete(
                withStatusCode: 200,
                data: emptyListJSON
            )
        }
    }
    
    func test_deliversFeedItemson200HTTPResponseWithFeedJsonList() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(id: UUID(), imageURL: URL(string: "a-url.com")!)
        let item2 = makeItem(id: UUID(), description: "desc", location: "location", imageURL: URL(string: "a-url.com")!)
        let items = [item1.model, item2.model]
        
        expect(sut, completeWith: .success(items)) {
            let data = makeItemsJson([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: data)
        }
    }
    
    func test_load_shouldNotDeliverResponseIfTheSUTIsDeallocated() {
        let client = HTTPClientSpy()
        let url = URL(string: "a-url.com")!
        var sut: RemoteFeedLoader? = RemoteFeedLoader(client: client, url: url)
        
        var capturedResult = [RemoteFeedLoader.Result]()
        sut?.load { capturedResult.append($0) }
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemsJson([]))
        
        XCTAssertTrue(capturedResult.isEmpty)
    }
    
    //MARK: - Helpers
    
    private func expect(
        _ sut: RemoteFeedLoader,
        completeWith expectedResult: RemoteFeedLoader.Result,
        action: ()->Void,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load to complete")
        
        sut.load { receivedResult in
            switch(receivedResult, expectedResult) {
            case let (.success(receivedFeedItems), .success(expectedFeedItems)):
                XCTAssertEqual(receivedFeedItems, expectedFeedItems, file: file, line: line)
            case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected \(expectedResult) got \(receivedResult)", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
     
    func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedItem, json: [String: Any]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].compactMapValues { $0 }
        
        return (item, json)
    }
    
    func makeItemsJson(_ items: [[String: Any]]) -> Data {
        let itemsJSON = ["items": items]
        return try!  JSONSerialization.data(withJSONObject: itemsJSON)
    }
    
    private func makeSUT(
        url: URL = URL(string: "a.url.com")!,
        file: StaticString = #file,
        line: UInt = #line
    ) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        trackForMemoryLeaks(instance: client, file: file, line: line)
        
        return (sut, client)
    }
    
    func failure(_ error: RemoteFeedLoader.Error) -> LoadFeedResult {
        return .failure(error)
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
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
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
