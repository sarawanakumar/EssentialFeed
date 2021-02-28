//
//  LocalFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 23/02/21.
//

import XCTest
import EssentialFeed

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
        let (store,sut) = makeSut()
        let deletionError = anyNSError()
        
        expect(sut: sut, toCompleteWith: deletionError) {
            store.completeDeletion(with: deletionError)
        }
    }
    
    func test_save_throwsErrorOnInsertionFailure() {
        let (store,sut) = makeSut()
        let insertionError = anyNSError()
        
        expect(sut: sut, toCompleteWith: insertionError) {
            store.completeDeletionSuccessfully()
            store.completionInsertion(with: insertionError)
        }
    }
    
    func test_save_succeedsOnSuccessfulCacheInsertion() {
        let (store,sut) = makeSut()
        
        expect(sut: sut, toCompleteWith: nil) {
            store.completeDeletionSuccessfully()
            store.completionInsertionSuccessfully()
        }
    }
    
    func test_doesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [Error?]()
        
        sut?.save([uniqueFeedItem()], completion: { receivedResults.append($0) })
        
        sut = nil
        
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_doesNotDeliverinsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [Error?]()
        
        sut?.save([uniqueFeedItem()], completion: { receivedResults.append($0) })
        
        
        store.completeDeletionSuccessfully()
        sut = nil

        store.completionInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    //: - Helpers
    func expect(sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        var receivedError: Error?
        let exp = expectation(description: "wait for save to complete")
        sut.save([uniqueFeedItem()]) { error in
            receivedError = error
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0 )
        
        XCTAssertEqual(receivedError as NSError?, expectedError, file:file, line: line)
    }
    
    private func makeSut(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (store: FeedStoreSpy, sut: LocalFeedLoader) {
        let store = FeedStoreSpy()
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
    
    private class FeedStoreSpy: FeedStore {
        enum ReceivedMessage: Equatable {
            case deleteCachedFeed
            case insert([FeedItem], Date)
        }
        
        //the collaborator has a order dependency on invoking methods of store. (insertion after delete) to gather all tracking to single var array
        var receivedMessages = [ReceivedMessage]()

        private var deletionCompletions = [DeletionCompletion]()
        private var insertionCompletions = [InsertionCompletion]()
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            deletionCompletions.append(completion)
            receivedMessages.append(.deleteCachedFeed)
        }
        
        func insert(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            insertionCompletions.append(completion)
            receivedMessages.append(.insert(items, timestamp))
        }
        
        func completeDeletion(with error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionSuccessfully(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completionInsertion(with error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completionInsertionSuccessfully(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
}
