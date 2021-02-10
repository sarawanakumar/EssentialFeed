//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 10/02/21.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public enum HTTPClientResult {
    case Success(HTTPURLResponse, Data)
    case Failure(Error)
}
