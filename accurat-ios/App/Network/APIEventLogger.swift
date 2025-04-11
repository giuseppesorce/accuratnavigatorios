//
//  APIEventLogger.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 10/04/25.
//

import Alamofire
import Foundation

// MARK: - Alamofire Event Logger
class APIEventLogger: EventMonitor {
    // Log request creation
    func request(_ request: Request, didCreateTask task: URLSessionTask) {
        print("🔵 API Request Created: \(request.description)")
    }

    // Log request completion with cURL command
    func request(_ request: Request, didCompleteTask task: URLSessionTask, with error: Error?) {
        // Capture complete request and response, but we can't access data here
        APIDebugHelper.logAPIDetails(
            request: request.request,
            response: request.response,
            responseData: nil,  // Data not accessible in this callback
            error: error
        )
    }
}
