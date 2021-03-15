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
    
    func test_validateCache_deletesTheCacheOnRetrievalError() {
        let (store, sut) = makeSut()
        
        sut.validateCache()
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_validateCache_doesNotDeletesTheCacheOnEmptyCache() {
        let (store, sut) = makeSut()
        
        sut.validateCache()
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_validateCache_doesNotDeletesTheCacheWhenCacheIsLessThanSevanDaysOld() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessthanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: 1)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.validateCache()
        store.completeRetrieval(with: feed.locals, timestamp: lessthanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let locals = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models, locals)
    }
    
    func uniqueImage() -> FeedImage {
        let url = URL(string: "a.url.com")!
        return FeedImage(id: UUID(), description: "anydesc", location: "anyloc", url: url)
    }
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(instance: store, file: file, line: line)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return (store, sut)
    }
    
    func anyNSError() -> NSError{
        return NSError(domain: "An Error ", code: 0)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian)
            .date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
