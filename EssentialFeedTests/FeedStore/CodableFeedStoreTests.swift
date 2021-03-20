//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 20/03/21.
//

import Foundation
import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }
    
    private struct CodableFeedImage: Codable {
        public let id: UUID
        public let description: String?
        public let location: String?
        public let url: URL
        
        init(_ localFeed: LocalFeedImage) {
            id = localFeed.id
            description = localFeed.description
            location = localFeed.location
            url = localFeed.url
        }
        
        var local: LocalFeedImage {
            LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        let decoder = JSONDecoder()
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feed.map({$0.local}), timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut: sut, toRetrieve: .empty)
    }
    
    func test_retrieve_deliversEmptyOnCallingRetrieveOnEmptyCacheTwice() {
        let sut = makeSUT()
        
        let exp = expectation(description: "wait for completion block")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("expected to return empty cache in both the times but instead \(firstResult) nad \(secondResult)")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingValue_deliversInsertedValue() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        
        let exp = expectation(description: "wait for completion block")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "insertion should be success")
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        
        expect(sut: sut, toRetrieve: .found(feed: feed, timestamp: timestamp))
    }
    
    func test_retrieveTwiceAfterInsertingValue_deliversTheSameInsertedValue() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
        
        let exp = expectation(description: "wait for completion block")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "insertion should be success")
            sut.retrieve { firstResult in
                sut.retrieve { secondResult in
                    switch (firstResult, secondResult) {
                    case let (.found(feed: firstFound, timestamp: firstTs), .found(feed: secondFound, timestamp: secondTs)):
                        XCTAssertEqual(firstFound, feed)
                        XCTAssertEqual(firstTs, timestamp)
                        
                        XCTAssertEqual(secondFound, feed)
                        XCTAssertEqual(secondTs, timestamp)
                    default:
                        XCTFail("expected to return Same inserted feed \(feed) for on both retrieves but got \(firstResult) and then \(secondResult)")
                    }
                    exp.fulfill()
                }
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func makeSUT(file: StaticString = #file, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        
        return sut
    }
    
    func expect(sut: CodableFeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait for completion")
        sut.retrieve { retrieveResult in
            switch (retrieveResult, expectedResult) {
            case (.empty, .empty):
                break
                
            case let (.found(feed: retrievedFeed, timestamp: retrievedTimestamp), .found(feed: expectedFeed, timestamp: expectedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
            default:
                XCTFail("expected to retrieve \(expectedResult) instead got \(retrieveResult)", file: file, line: line)
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
}
