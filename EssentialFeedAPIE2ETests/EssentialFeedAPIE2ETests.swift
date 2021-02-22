//
//  EssentialFeedAPIE2ETests.swift
//  EssentialFeedAPIE2ETests
//
//  Created by Saravanakumar S on 12/02/21.
//

import XCTest
import EssentialFeed

class EssentialFeedAPIE2ETests: XCTestCase {
    
    //Default path of cache when testing => (/Users/{your-user-name}/Library/Caches/com.apple.dt.xctest.tool)
    //When running the app => (user home directory)/Library/Caches/(application bundle id)
//    func demo()  {
//        let cache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)
//        let config = URLSessionConfiguration.default
//        config.urlCache = cache
//        config.requestCachePolicy = .reloadIgnoringLocalCacheData //Always load from remote
//        let session = URLSession(configuration: config)
//
//        //if you want to have cache policy per request
//        let url = URL(string: "a.url.com")!
//        let urlRequest = URLRequest(url: url, cachePolicy: .returnCacheDataDontLoad, timeoutInterval: 30)
//        //The server should allow the particular request to be cached
//        //e.g.response should have a header called Cache-Control [Cache-Control: public, max-age=14400]
//
//        //OR
//        //URLCache.shared = cache
//        //This must be as early as the app has lauched, in order for the config to set correctly
//        //applicationDidFinishLaunching
//
//        //Not a good candidate for persisting offline data
//    }

    func test_e2eServerGETFeedResult_MatchesFeedWithTestAccount() {
        let receivedResult = getFeedResult()
        
        switch receivedResult {
        case let .success(items)?:
            XCTAssertEqual(items[0], getItem(at: 0))
            XCTAssertEqual(items[1], getItem(at: 1))
            XCTAssertEqual(items[2], getItem(at: 2))
            XCTAssertEqual(items[3], getItem(at: 3))
            XCTAssertEqual(items[4], getItem(at: 4))
            XCTAssertEqual(items[5], getItem(at: 5))
            XCTAssertEqual(items[6], getItem(at: 6))
            XCTAssertEqual(items[7], getItem(at: 7))
        case let .failure(error)?:
            XCTFail("Expected successful result but got error \(error)")
        default:
            XCTFail("Expected to pass")
        }
    }

    // MARK: - Helper methods
    
    func getFeedResult(file: StaticString = #file, line: UInt = #line) -> LoadFeedResult? {
        let testURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
        let loader = RemoteFeedLoader(client: client, url: testURL)
        var receivedResult: LoadFeedResult?
        
        trackForMemoryLeaks(instance: client, file: file, line: line)
        trackForMemoryLeaks(instance: loader, file: file, line: line)
        
        let exp = expectation(description: "Wait for api call to return")
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        wait(for: [exp], timeout: 20.0)
        
        return receivedResult
    }
    
    func getItem(at index: Int) -> FeedItem {
        return FeedItem(id: getId(at: index), description: getDesc(at: index), location: getLocation(at: index), imageURL: getImageURL(at: index))
    }
    
    func getId(at i: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][i])!
    }
    
    func getDesc(at index: Int) -> String? {
        return ["Description 1",
                nil,
                "Description 3",
                nil,
                "Description 5",
                "Description 6",
                "Description 7",
                "Description 8"][index]
    }
    
    func getLocation(at index: Int) -> String? {
        return ["Location 1",
                "Location 2",
                nil,
                nil,
                "Location 5",
                "Location 6",
                "Location 7",
                "Location 8"][index]
    }
    
    func getImageURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index+1).com")!
    }
}
