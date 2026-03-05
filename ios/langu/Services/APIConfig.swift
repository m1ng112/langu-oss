import Foundation

enum APIConfig {
    static var baseURL: String {
        if let envURL = ProcessInfo.processInfo.environment["LANGU_API_URL"] {
            return envURL
        }
        #if DEBUG
        return "http://localhost:8787"
        #else
        return "https://langu-api.ko-with-ja.workers.dev"
        #endif
    }

    static var assessEndpoint: String { "\(baseURL)/api/v1/assess" }
    static var ttsEndpoint: String { "\(baseURL)/api/v1/tts" }
    static var evaluateThemeEndpoint: String { "\(baseURL)/api/v1/evaluate-theme" }
}
