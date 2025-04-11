//
//  AFInterceptor.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 10/04/25.
//

import Alamofire
import Foundation

// MARK: - RequestInterceptor for logging
class LoggingInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        // Simply pass through the request without modification
        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        // Don't retry, just log
        completion(.doNotRetry)
    }
}

// MARK: - Alamofire Session Extension
extension Session {
    static var loggingEnabled: Session = {
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default

        let interceptor = LoggingInterceptor()
        let logger = APIEventLogger()

        return Session(
            configuration: configuration,
            interceptor: interceptor,
            eventMonitors: [logger]
        )
    }()
}
