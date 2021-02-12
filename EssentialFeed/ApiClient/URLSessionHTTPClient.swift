//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Saravanakumar S on 12/02/21.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private struct UnexpectedErrorRepresentation: Error {}
    
    var urlSession: URLSession
    
    public init(session: URLSession = .shared) {
        self.urlSession = session
    }
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        let task = urlSession.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.Failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.Success(response, data))
            } else {
                completion(.Failure(UnexpectedErrorRepresentation()))
            }
        }
        task.resume()
    }
}
