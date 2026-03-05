import Foundation

@Observable
final class ThemeEvaluationService {
    var isEvaluating = false

    private let apiEndpoint = APIConfig.evaluateThemeEndpoint

    enum EvaluationError: Error, LocalizedError {
        case networkError(String)
        case requestFailed(Int, String)
        case decodingFailed(String)
        case emptyText

        var errorDescription: String? {
            switch self {
            case .networkError(let msg): return "Network error: \(msg)"
            case .requestFailed(let code, let msg): return "API error (\(code)): \(msg)"
            case .decodingFailed(let detail): return "Failed to parse response: \(detail)"
            case .emptyText: return "No speech was recognized. Please try again."
            }
        }
    }

    func evaluate(recognizedText: String, theme: Theme) async throws -> ThemeEvaluation {
        guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw EvaluationError.emptyText
        }

        isEvaluating = true
        defer { isEvaluating = false }

        let requestBody: [String: Any] = [
            "recognizedText": recognizedText,
            "themeId": theme.id,
            "themeName": theme.koreanName,
            "themeDescription": theme.description,
            "keywords": theme.keywords,
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw EvaluationError.networkError(error.localizedDescription)
        }

        if let raw = String(data: data, encoding: .utf8) {
            print("[Theme Evaluation Response] \(raw)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EvaluationError.decodingFailed("Invalid HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw EvaluationError.requestFailed(httpResponse.statusCode, body)
        }

        return try parseResponse(data, themeId: theme.id, recognizedText: recognizedText)
    }

    private func parseResponse(_ data: Data, themeId: String, recognizedText: String) throws -> ThemeEvaluation {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "(binary)"
            throw EvaluationError.decodingFailed(raw)
        }

        guard let success = json["success"] as? Bool, success else {
            if let error = json["error"] as? String {
                throw EvaluationError.requestFailed(400, error)
            }
            throw EvaluationError.decodingFailed("Unknown error")
        }

        guard let scoreData = json["data"] as? [String: Any] else {
            throw EvaluationError.decodingFailed("Missing data in response")
        }

        let relevanceScore = scoreData["relevanceScore"] as? Int ?? 0
        let vocabularyScore = scoreData["vocabularyScore"] as? Int ?? 0
        let grammarScore = scoreData["grammarScore"] as? Int ?? 0
        let expressionScore = scoreData["expressionScore"] as? Int ?? 0
        let overallScore = scoreData["overallScore"] as? Int
            ?? (relevanceScore + vocabularyScore + grammarScore + expressionScore) / 4
        let feedback = scoreData["feedback"] as? String ?? ""
        let usedKeywords = scoreData["usedKeywords"] as? [String] ?? []
        let suggestedVocabulary = scoreData["suggestedVocabulary"] as? [String] ?? []

        // Parse detailed feedback
        var details: [FeedbackDetail] = []
        if let detailsArray = scoreData["detailedFeedback"] as? [[String: Any]] {
            for detail in detailsArray {
                if let typeStr = detail["type"] as? String,
                   let message = detail["message"] as? String,
                   let type = FeedbackDetail.DetailType(rawValue: typeStr) {
                    details.append(FeedbackDetail(type: type, message: message))
                }
            }
        }

        // Fallback: generate details from scores if backend didn't provide them
        if details.isEmpty {
            details = generateFallbackDetails(
                relevance: relevanceScore,
                vocabulary: vocabularyScore,
                grammar: grammarScore,
                expression: expressionScore
            )
        }

        let xp = xpForScore(overallScore)

        return ThemeEvaluation(
            themeId: themeId,
            recognizedText: recognizedText,
            overallScore: overallScore,
            relevanceScore: relevanceScore,
            vocabularyScore: vocabularyScore,
            grammarScore: grammarScore,
            expressionScore: expressionScore,
            feedback: feedback,
            details: details,
            usedKeywords: usedKeywords,
            suggestedVocabulary: suggestedVocabulary,
            xpEarned: xp
        )
    }

    private func generateFallbackDetails(relevance: Int, vocabulary: Int, grammar: Int, expression: Int) -> [FeedbackDetail] {
        var details: [FeedbackDetail] = []

        if relevance >= 85 {
            details.append(FeedbackDetail(type: .excellent, message: "Your response is highly relevant to the theme."))
        }
        if vocabulary >= 80 {
            details.append(FeedbackDetail(type: .good, message: "Good vocabulary usage for this topic."))
        }
        if grammar < 70 {
            details.append(FeedbackDetail(type: .tip, message: "Try to use more complete sentence structures with proper endings."))
        }
        if expression < 70 {
            details.append(FeedbackDetail(type: .tip, message: "Try using more varied expressions and longer sentences."))
        }

        if details.isEmpty {
            details.append(FeedbackDetail(type: .good, message: "Keep practicing to improve your free speech skills."))
        }

        return details
    }

    private func xpForScore(_ score: Int) -> Int {
        switch score {
        case 90...100: return 60
        case 70..<90: return 40
        case 50..<70: return 25
        default: return 15
        }
    }
}
