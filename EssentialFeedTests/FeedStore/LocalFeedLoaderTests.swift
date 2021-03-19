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
        let (store,sut) = makeSut()
        
        sut.save(uniqueImageFeed().models) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_doesnotRequestCacheInsertionOnDeleteError() {
        let (store,sut) = makeSut()
        let deletionError = anyNSError()
        sut.save(uniqueImageFeed().models) { _ in }
        
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
    }
    
    func test_save_requestsNewCachInsertionWithTimestampOnDeletionSuccess() {
        let timestamp = Date()
        let feed = uniqueImageFeed()
        let (store,sut) = makeSut(currentDate: { timestamp })
        sut.save(feed.models) { _ in }
        
        store.completeDeletionSuccessfully()
        
        XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.locals, timestamp)])
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
        var receivedResults = [LocalFeedLoader.SaveResult]()
        
        sut?.save(uniqueImageFeed().models, completion: { receivedResults.append($0) })
        
        sut = nil
        
        store.completeDeletion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func test_doesNotDeliverinsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.SaveResult]()
        
        sut?.save([uniqueImage()], completion: { receivedResults.append($0) })
        
        
        store.completeDeletionSuccessfully()
        sut = nil

        store.completionInsertion(with: anyNSError())
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    //: - Helpers
    func expect(sut: LocalFeedLoader, toCompleteWith expectedError: NSError?, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        
        var receivedError: LocalFeedLoader.SaveResult = nil
        let exp = expectation(description: "wait for save to complete")
        sut.save(uniqueImageFeed().models) { error in
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
}