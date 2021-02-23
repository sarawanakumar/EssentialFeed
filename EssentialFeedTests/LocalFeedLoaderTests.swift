//
//  LocalFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 23/02/21.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    private let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem])  {
        store.deleteCachedFeed()
    }
}
class FeedStore {
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    
    func deleteCachedFeed() {
        deleteCachedFeedCallCount += 1
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        
    }
}

class LocalFeedLoaderTests: XCTestCase {

    func test_init_doesNotDeleteCachedFeedUponCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestCacheDeleteion() {
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut()
        
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_doesnotRequestCacheInsertionOnDeleteError() {
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut()
        let deletionError = anyNSError()
        sut.save(items)
        
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    //: - Helpers
    func makeSut(file: StaticString = #file, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        trackForMemoryLeaks(instance: store, file: file, line: line)
        trackForMemoryLeaks(instance: sut, file: file, line: line)
        return (store, sut)
    }
    
    func uniqueFeedItem() -> FeedItem {
        let url = URL(string: "a.url.com")!
        return FeedItem(id: UUID(), description: "anydesc", location: "anyloc", imageURL: url)
    }
    
    func anyNSError() -> NSError{
        return NSError(domain: "An Error ", code: 0)
    }
}
