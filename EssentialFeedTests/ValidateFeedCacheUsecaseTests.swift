//
//  ValidateFeedCacheUsecaseTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 15/03/21.
//

import Foundation
import XCTest
import EssentialFeed


class ValidateFeedCacheUsecaseTests: XCTestCase {
    
    func test_init_doesNotMessageStoreUponCreation() {
        let (store, _) = makeSut()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(instance: store, file: file, line: line)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return (store, sut)
    }
}
