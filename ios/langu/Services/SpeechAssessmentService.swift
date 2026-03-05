import Foundation

@Observable
final class SpeechAssessmentService {
    var isAssessing = false

    // API endpoint - uses Cloudflare Workers proxy
    private let apiEndpoint = APIConfig.assessEndpoint

    struct WordAssessment: Identifiable {
        let id = UUID()
        let word: String
        let accuracyScore: Int
        let errorType: ErrorType

        enum ErrorType: String {
            case none
            case mispronunciation
            case omission
            case insertion

            var displayName: String {
                switch self {
                case .none: return "Good"
                case .mispronunciation: return "Mispronounced"
                case .omission: return "Omitted"
                case .insertion: return "Extra"
                }
            }
        }

        var isGood: Bool { accuracyScore >= 80 && errorType == .none }
        var needsWork: Bool { accuracyScore < 60 || errorType != .none }
    }

    struct AssessmentResult {
        let pronunciationScore: Int
        let accuracyScore: Int
        let fluencyScore: Int
        let prosodyScore: Int
        let completenessScore: Int
        let recognizedText: String?
        let words: [WordAssessment]

        var overallScore: Int {
            (pronunciationScore * 3 + accuracyScore * 3 + fluencyScore * 2 + prosodyScore * 2) / 10
        }
    }

    enum AssessmentError: Error, LocalizedError {
        case audioReadFailed
        case audioTooShort
        case networkError(String)
        case requestFailed(Int, String)
        case decodingFailed(String)
        case noSpeechDetected

        var errorDescription: String? {
            switch self {
            case .audioReadFailed: return "Failed to read audio file."
            case .audioTooShort: return "Recording too short. Hold the button longer."
            case .networkError(let msg): return "Network error: \(msg)"
            case .requestFailed(let code, let msg): return "API error (\(code)): \(msg)"
            case .decodingFailed(let detail): return "Failed to parse response: \(detail)"
            case .noSpeechDetected: return "No speech detected. Please speak clearly into the microphone and try again."
            }
        }
    }

    func assess(audioURL: URL, referenceText: String) async throws -> AssessmentResult {
        isAssessing = true
        defer { isAssessing = false }

        guard let audioData = try? Data(contentsOf: audioURL) else {
            throw AssessmentError.audioReadFailed
        }

        // WAV header is 44 bytes; need actual audio content
        if audioData.count < 1000 {
            throw AssessmentError.audioTooShort
        }

        // Build request body for proxy API
        let requestBody: [String: Any] = [
            "audio": audioData.base64EncodedString(),
            "referenceText": referenceText
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        // Build request
        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw AssessmentError.networkError(error.localizedDescription)
        }

        // Log full response for debugging
        if let raw = String(data: data, encoding: .utf8) {
            print("[API Response] \(raw)")
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AssessmentError.decodingFailed("Invalid HTTP response")
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AssessmentError.requestFailed(httpResponse.statusCode, body)
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> AssessmentResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            let raw = String(data: data, encoding: .utf8) ?? "(binary)"
            throw AssessmentError.decodingFailed(raw)
        }

        // Check success flag from proxy response
        guard let success = json["success"] as? Bool, success else {
            if let error = json["error"] as? String {
                if error.contains("NoMatch") || error.contains("InitialSilenceTimeout") {
                    throw AssessmentError.noSpeechDetected
                }
                throw AssessmentError.requestFailed(400, error)
            }
            throw AssessmentError.decodingFailed("Unknown error")
        }

        // Extract scores from data object
        guard let scoreData = json["data"] as? [String: Any] else {
            throw AssessmentError.decodingFailed("Missing data in response")
        }

        let pronScore = scoreData["pronunciationScore"] as? Int ?? 0
        let accScore = scoreData["accuracyScore"] as? Int ?? 0
        let fluScore = scoreData["fluencyScore"] as? Int ?? 0
        let compScore = scoreData["completenessScore"] as? Int ?? 0
        let recognizedText = scoreData["recognizedText"] as? String

        // Parse words array
        var words: [WordAssessment] = []
        if let wordsArray = scoreData["words"] as? [[String: Any]] {
            for wordData in wordsArray {
                if let word = wordData["word"] as? String {
                    let accuracyScore = wordData["accuracyScore"] as? Int ?? 0
                    let errorTypeStr = wordData["errorType"] as? String ?? "none"
                    let errorType = WordAssessment.ErrorType(rawValue: errorTypeStr) ?? .none
                    words.append(WordAssessment(word: word, accuracyScore: accuracyScore, errorType: errorType))
                }
            }
        }

        // Prosody score with fallback estimation
        let prosodyScore: Int
        if let prosody = scoreData["prosodyScore"] as? Int, prosody > 0 {
            prosodyScore = prosody
        } else {
            prosodyScore = max(0, (pronScore + accScore) / 2 - 5)
        }

        return AssessmentResult(
            pronunciationScore: pronScore,
            accuracyScore: accScore,
            fluencyScore: fluScore,
            prosodyScore: prosodyScore,
            completenessScore: compScore,
            recognizedText: recognizedText,
            words: words
        )
    }

    func buildFeedback(from result: AssessmentResult, lesson: Lesson) -> LessonFeedback {
        let score = result.overallScore
        let emoji: String
        let message: String
        let xp: Int

        switch score {
        case 90...100:
            emoji = "🎉"
            message = "Outstanding pronunciation!"
            xp = 50
        case 70..<90:
            emoji = "😊"
            message = "Great effort! Keep practicing."
            xp = 35
        case 50..<70:
            emoji = "💪"
            message = "Good start! Try again for a better score."
            xp = 20
        default:
            emoji = "🔄"
            message = "Keep trying, you'll get there!"
            xp = 10
        }

        // Convert WordAssessment to WordFeedback
        let wordFeedbacks = result.words.map { word in
            WordFeedback(
                word: word.word,
                accuracyScore: word.accuracyScore,
                errorType: WordFeedback.ErrorType(rawValue: word.errorType.rawValue) ?? .none
            )
        }

        return LessonFeedback(
            overallScore: score,
            emoji: emoji,
            message: message,
            xpEarned: xp,
            scores: [
                ScoreAxis(label: "Pronunciation", koreanLabel: "발음", value: result.pronunciationScore, icon: "mic.fill"),
                ScoreAxis(label: "Accuracy", koreanLabel: "정확도", value: result.accuracyScore, icon: "target"),
                ScoreAxis(label: "Fluency", koreanLabel: "유창성", value: result.fluencyScore, icon: "waveform.path"),
                ScoreAxis(label: "Prosody", koreanLabel: "억양", value: result.prosodyScore, icon: "music.note"),
                ScoreAxis(label: "Completeness", koreanLabel: "완성도", value: result.completenessScore, icon: "checkmark.circle.fill"),
            ],
            details: generateDetails(result: result, lesson: lesson),
            recognizedText: result.recognizedText,
            referenceText: lesson.korean,
            words: wordFeedbacks
        )
    }

    private func generateDetails(result: AssessmentResult, lesson: Lesson) -> [FeedbackDetail] {
        var details: [FeedbackDetail] = []

        if result.pronunciationScore >= 85 {
            details.append(FeedbackDetail(type: .excellent, message: "Your pronunciation of '\(lesson.korean)' is very clear and natural."))
        }
        if result.fluencyScore >= 60 {
            details.append(FeedbackDetail(type: .good, message: "Good rhythm and pacing between syllables."))
        }
        if result.accuracyScore < 80 {
            details.append(FeedbackDetail(type: .tip, message: "\(lesson.hint)"))
        } else if result.overallScore < 90 {
            details.append(FeedbackDetail(type: .tip, message: "Try to soften consonant transitions for a more native sound."))
        }

        if details.isEmpty {
            details.append(FeedbackDetail(type: .excellent, message: "Perfect score! Your Korean sounds very natural."))
        }

        return details
    }
}
