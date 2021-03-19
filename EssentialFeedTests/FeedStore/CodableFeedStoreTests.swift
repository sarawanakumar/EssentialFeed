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
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

class CodableFeedStoreTests: XCTestCase {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        
        let exp = expectation(description: "wait for completion block")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("expected to return empty cache instead \(result)")
            }
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_deliversEmptyOnCallingRetrieveOnEmptyCacheTwice() {
        let sut = CodableFeedStore()
        
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
}
