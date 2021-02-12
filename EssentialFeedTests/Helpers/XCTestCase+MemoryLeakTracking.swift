//
//  XCTestCase+MemoryLeakTracking.swift
//  EssentialFeedTests
//
//  Created by Saravanakumar S on 12/02/21.
//

import Foundation
import XCTest 

extension XCTestCase {
    func trackForMemoryLeaks(instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
        addTeardownBlock { [weak instance] in //checks, if sut is dealloced as the invocation completes?
            XCTAssertNil(instance, "instance should have been deallocated", file: file, line: line)
        }
    }
}
