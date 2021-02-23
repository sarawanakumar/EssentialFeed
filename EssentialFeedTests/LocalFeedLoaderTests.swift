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
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void)  {
        store.deleteCachedFeed { [unowned self] error in
            completion(error)
            if error == nil {
                self.store.insert(items, timestamp: self.currentDate())
            }
        }
    }
}
class FeedStore {
    typealias DeletionCompletion = (Error?)->Void
    
    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([FeedItem], Date)
    }
    
    //the collaborator has a order dependency on invoking methods of store. (insertion after delete) to gather all tracking to single var array
    var receivedMessages = [ReceivedMessage]()

    private var deletionCompletions = [DeletionCompletion]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func insert(_ items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insert(items, timestamp))
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
}

class LocalFeedLoaderTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (store, _) = makeSut()
        
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestCacheDeleteion() {
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut()
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesnotRequestCacheInsertionOnDeleteError() {
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut()
        let deletionError = anyNSError()
        sut.save(items) { _ in }
        
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCachInsertionWithTimestampOnDeletionSuccess() {
        let timestamp = Date()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut(currentDate: { timestamp })
        sut.save(items) { _ in }
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(items, timestamp)])
    }
    
    func test_save_throwsErrorOnDeletionFailure() {
        let timestamp = Date()
        let items = [uniqueFeedItem(), uniqueFeedItem()]
        let (store,sut) = makeSut(currentDate: { timestamp })
        var receivedError: Error?
        let deletionError = anyNSError()
        let exp = expectation(description: "wait for save to complete")
        sut.save(items) { error in
            receivedError = error
            exp.fulfill()
        }
        
        store.completeDeletion(with: deletionError)
        
        wait(for: [exp], timeout: 1.0 )
        
        XCTAssertEqual(receivedError as NSError?, deletionError)
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
