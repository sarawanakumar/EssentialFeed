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
    private let currentDate: () -> Date
    
    init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem])  {
        store.deleteCachedFeed { [unowned self] error in
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}
class FeedStore {
    var deleteCachedFeedCallCount = 0
    var insertCallCount = 0
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    typealias DeletionCompletion = (Error?)->Void
    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        deletionCompletions.append(completion)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertions.append((items: items, timestamp: timestamp))
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
}

class LocalFeedLoaderTests: XCTestCase {

    func test_init_doesNotDeleteCachedFeedUponCreation() {
        let (store, _) = makeSut()
        
        
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
    
    func test_save_requestsNewCachInsertionOnDeletionSuccess() {
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut()
        sut.save(items)
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    func test_save_requestsNewCachInsertionWithTimestampOnDeletionSuccess() {
        let timestamp = Date()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut(currentDate: { timestamp })
        sut.save(items)
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }
    
    //: - Helpers
    func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStore, sut: LocalFeedLoader) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
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
