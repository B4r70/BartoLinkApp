//
//  APIClient.swift
//  bartolink
//
//  HTTP-Client für das barto-link-Backend.
//  Authentifiziert sich mit Bearer-Token aus Config.swift.
//
//  Sprint 3b: + refreshTrip(tripKey)
//

import Foundation
import os.log


// MARK: - DTOs (mit Backend abgestimmt)

struct TokenRegisterRequest: Encodable {
    let token: String
    let bundle_id: String
    let environment: String
    let device_label: String?
}


struct TokenRegisterResponse: Decodable {
    let id: Int
    let token_preview: String
    let is_active: Bool
    let created_at: String
    let updated_at: String
}


// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case throttled(TripRefreshThrottled)
    case serverError(status: Int, body: String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Antwort ungültig"
        case .unauthorized:
            return "API-Token ungültig oder fehlt"
        case .throttled(let info):
            return info.localizedDescription
        case .serverError(let status, let body):
            return "Server-Fehler \(status): \(body)"
        case .networkError(let err):
            return "Netzwerk-Fehler: \(err.localizedDescription)"
        case .decodingError(let err):
            return "Decoding-Fehler: \(err.localizedDescription)"
        }
    }
}


// MARK: - Client

actor APIClient {

    static let shared = APIClient()

    private let logger = Logger(subsystem: "com.barto.bartolink", category: "API")
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }


    // MARK: - Public

    /// Registriert (oder aktualisiert) einen Push-Token beim Backend.
    func registerToken(_ deviceToken: String) async throws -> TokenRegisterResponse {
        let payload = TokenRegisterRequest(
            token: deviceToken,
            bundle_id: Config.bundleID,
            environment: Config.apnsEnvironment,
            device_label: Config.deviceLabel
        )

        return try await post(
            path: "/tokens/register",
            body: payload,
            responseType: TokenRegisterResponse.self
        )
    }

    /// Triggert einen manuellen Refresh für einen Trip.
    ///
    /// Backend-Verhalten:
    ///   - 200: Refresh hat geklappt, neuer Stand kommt zurück.
    ///   - 429: Rate-Limit (per_trip oder global) — wirft `APIError.throttled`.
    ///   - 502: dbticker-Aufruf ist gescheitert (z.B. Route nicht in routes.toml,
    ///          DB-API antwortet nicht, etc.) — wirft `APIError.serverError`.
    func refreshTrip(_ tripKey: String) async throws -> TripRefreshResponse {
        return try await postNoBody(
            path: "/trips/\(tripKey)/refresh",
            responseType: TripRefreshResponse.self
        )
    }


    // MARK: - Generic POST mit Body

    private func post<RequestBody: Encodable, ResponseBody: Decodable>(
        path: String,
        body: RequestBody,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        let url = Config.backendURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            throw APIError.decodingError(error)
        }

        return try await execute(request: request, path: path, responseType: responseType)
    }


    // MARK: - Generic POST ohne Body

    /// Wie post(), nur ohne Body — für /trips/{key}/refresh.
    private func postNoBody<ResponseBody: Decodable>(
        path: String,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        let url = Config.backendURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(Config.apiToken)", forHTTPHeaderField: "Authorization")

        return try await execute(request: request, path: path, responseType: responseType)
    }


    // MARK: - Execute (gemeinsamer Pfad)

    private func execute<ResponseBody: Decodable>(
        request: URLRequest,
        path: String,
        responseType: ResponseBody.Type
    ) async throws -> ResponseBody {
        logger.info("\(request.httpMethod ?? "?") \(path)")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            logger.error("Network error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        let statusCode = httpResponse.statusCode

        switch statusCode {
        case 200...299:
            do {
                let decoded = try JSONDecoder().decode(ResponseBody.self, from: data)
                logger.info("✅ \(path) → \(statusCode)")
                return decoded
            } catch {
                logger.error("Decoding failed: \(error.localizedDescription)")
                throw APIError.decodingError(error)
            }

        case 401, 403:
            logger.error("Auth failed for \(path)")
            throw APIError.unauthorized

        case 429:
            // Rate-Limit — Body enthält retry_after_seconds + reason
            do {
                let throttle = try JSONDecoder().decode(TripRefreshThrottled.self, from: data)
                logger.info("Throttled (\(throttle.reason), retry in \(throttle.retry_after_seconds)s)")
                throw APIError.throttled(throttle)
            } catch let apiError as APIError {
                throw apiError
            } catch {
                throw APIError.decodingError(error)
            }

        default:
            let body = String(data: data, encoding: .utf8) ?? "<no body>"
            logger.error("Server error \(statusCode) for \(path): \(body)")
            throw APIError.serverError(status: statusCode, body: body)
        }
    }
}
