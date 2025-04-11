//
//  APIDebugHelper.swift
//  accurat-ios
//
//  Created by Federico Malagoni on 10/04/25.
//

import Alamofire
import Foundation

// MARK: - APIDebugHelper
class APIDebugHelper {

    /// Converts an Alamofire Request to a cURL command string
    static func cURLCommand(from request: URLRequest) -> String {
        guard let url = request.url else { return "$ curl command couldn't be created" }

        var command = ["$ curl -v"]

        // Add HTTP method if not GET
        if let method = request.httpMethod, method != "GET" {
            command.append("-X \(method)")
        }

        // Add headers
        if let headers = request.allHTTPHeaderFields {
            for (key, value) in headers where key != "Cookie" {
                command.append("-H '\(key): \(value)'")
            }
        }

        // Add body data if present
        if let bodyData = request.httpBody, let bodyString = String(data: bodyData, encoding: .utf8) {
            // Escape single quotes in the body
            let escapedBody = bodyString.replacingOccurrences(of: "'", with: "'\\''")
            command.append("-d '\(escapedBody)'")
        }

        // Assemble the URL with query parameters
        var urlString = url.absoluteString
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedQuery {
            urlString = "\(url.scheme!)://\(url.host!)\(url.path)"
            command.append("'\(urlString)?\(queryItems)'")
        } else {
            command.append("'\(urlString)'")
        }

        return command.joined(separator: " ")
    }

    /// Logs the full API request and response details
    static func logAPIDetails(request: URLRequest?, response: HTTPURLResponse?, responseData: Data?, error: Error?) {
        print("\n------- API Debug Log -------")

        // Log the cURL command
        if let request = request {
            let curlCommand = cURLCommand(from: request)
            print("📋 cURL Command:")
            print(curlCommand)
            print("")
        }

        // Log request details
        if let request = request {
            print("📤 Request:")
            print("URL: \(request.url?.absoluteString ?? "nil")")
            print("Method: \(request.httpMethod ?? "GET")")

            if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
                print("Headers: \(headers)")
            }

            if let bodyData = request.httpBody,
               let bodyString = String(data: bodyData, encoding: .utf8) {
                print("Body: \(bodyString)")
            }
            print("")
        }

        // Log response details
        if let response = response {
            print("📥 Response:")
            print("Status Code: \(response.statusCode)")
            print("Headers: \(response.allHeaderFields)")

            if let data = responseData {
                if let json = try? JSONSerialization.jsonObject(with: data),
                   let prettyData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let prettyString = String(data: prettyData, encoding: .utf8) {
                    print("Body: \(prettyString)")
                } else if let string = String(data: data, encoding: .utf8) {
                    print("Body: \(string)")
                } else {
                    print("Body: \(data.count) bytes of binary data")
                }
            } else {
                print("Body: nil")
            }
        }

        // Log error if present
        if let error = error {
            print("❌ Error: \(error.localizedDescription)")

            if let afError = error as? AFError {
                switch afError {
                case .responseValidationFailed(let reason):
                    print("Validation Failed: \(reason)")
                case .responseSerializationFailed(let reason):
                    print("Serialization Failed: \(reason)")
                default:
                    print("Other AF Error: \(afError)")
                }
            }
        }

        print("------- End API Debug Log -------\n")
    }
}
