//
//  LoadFeedFromCacheUsecaseTests.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 02/03/21.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUsecaseTests: XCTestCase {

    func test_init_doesNotMessageStoreUponCreation() {
        let (store, _) = makeSut()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetrieval() {
        let (store, sut) = makeSut()
        
        sut.load() { _ in }
         
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievalError() {
        let (store, sut) = makeSut()
        let retrievalError = anyNSError()
        
        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetrieval(with: retrievalError)
        }
    }
    
    func test_load_deliversNoImageOnEmptyCache() {
        let (store, sut) = makeSut()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrievalWithEmptyCache()
        }
    }
    
    func test_load_deliversCachedImagesOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessthanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetrieval(with: feed.locals, timestamp: lessthanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessthanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.locals, timestamp: lessthanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_deliversNoImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessthanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrieval(with: feed.locals, timestamp: lessthanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_hasNoSideEffectOnRetrievalError() {
        let (store, sut) = makeSut()
        
        sut.load { _ in }
        store.completeRetrieval(with: anyNSError())
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnEmptyCache() {
        let (store, sut) = makeSut()
        
        sut.load { _ in }
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectsOnLessThanSevanDaysOld() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessthanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: 1)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.locals, timestamp: lessthanSevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }
    
    func test_load_deletesTheCacheWhenCacheIsSevanDaysOld() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.locals, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_deletesTheCacheWhenCacheIsMoreThanSevanDaysOld() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let sevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(days: -1)
        let (store, sut) = makeSut(currentDate: { fixedCurrentDate })
        
        sut.load { _ in }
        store.completeRetrieval(with: feed.locals, timestamp: sevenDaysOldTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCachedFeed])
    }
    
    func test_load_doesnotDeliversResultAfterSUTInstanceDealloc() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        var receivedResults = [LocalFeedLoader.LoadResult]()
        
        sut?.load(completion: {
            receivedResults.append($0)
        })
        
        sut = nil
        store.completeRetrievalWithEmptyCache()
        
        XCTAssertTrue(receivedResults.isEmpty)
    }
    
    func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        let exp = expectation(description: "wait")
        sut.load { receivedResult in
            
            switch (receivedResult, expectedResult) {
            case let (.success(recievedImages), .success(expectedImages)):
                XCTAssertEqual(recievedImages, expectedImages, file: file, line: line)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("expected result, got \(receivedResult)")
            }
            exp.fulfill()
        }

        action()
        wait(for: [exp], timeout: 1.0)
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
    
    func uniqueImage() -> FeedImage {
        let url = URL(string: "a.url.com")!
        return FeedImage(id: UUID(), description: "anydesc", location: "anyloc", url: url)
    }
    
    func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let locals = models.map {
            LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)
        }
        return (models, locals)
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
