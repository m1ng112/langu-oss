import AVFoundation
import SwiftUI

@Observable
final class TTSService: NSObject {
    var isLoading = false
    var isPlaying = false
    var error: Error?

    private var audioPlayer: AVAudioPlayer?
    private var audioCache: [String: Data] = [:]
    private let cacheQueue = DispatchQueue(label: "com.langu.tts.cache")

    // API endpoint
    private let apiEndpoint = APIConfig.ttsEndpoint

    // Available Korean voices
    enum KoreanVoice: String, CaseIterable {
        case wavenetFemaleA = "ko-KR-Wavenet-A"
        case wavenetFemaleB = "ko-KR-Wavenet-B"
        case wavenetMaleC = "ko-KR-Wavenet-C"
        case wavenetMaleD = "ko-KR-Wavenet-D"

        var displayName: String {
            switch self {
            case .wavenetFemaleA: return "Female 1"
            case .wavenetFemaleB: return "Female 2"
            case .wavenetMaleC: return "Male 1"
            case .wavenetMaleD: return "Male 2"
            }
        }
    }

    // MARK: - Public API

    /// Speak the given Korean text
    func speak(
        _ text: String,
        voice: KoreanVoice = .wavenetFemaleA,
        speakingRate: Double = 0.9
    ) async throws {
        // Check cache first
        let cacheKey = "\(text)_\(voice.rawValue)_\(speakingRate)"
        if let cachedAudio = getCachedAudio(for: cacheKey) {
            try await playAudio(data: cachedAudio)
            return
        }

        // Fetch from API
        isLoading = true
        defer { isLoading = false }

        let audioData = try await fetchAudio(text: text, voice: voice, speakingRate: speakingRate)

        // Cache the audio
        cacheAudio(audioData, for: cacheKey)

        // Play the audio
        try await playAudio(data: audioData)
    }

    /// Preload audio for a text (useful for lesson preloading)
    func preload(
        _ text: String,
        voice: KoreanVoice = .wavenetFemaleA,
        speakingRate: Double = 0.9
    ) async {
        let cacheKey = "\(text)_\(voice.rawValue)_\(speakingRate)"

        // Skip if already cached
        if getCachedAudio(for: cacheKey) != nil { return }

        do {
            let audioData = try await fetchAudio(text: text, voice: voice, speakingRate: speakingRate)
            cacheAudio(audioData, for: cacheKey)
        } catch {
            print("[TTSService] Preload failed: \(error)")
        }
    }

    /// Stop current playback
    func stop() {
        audioPlayer?.stop()
        isPlaying = false
    }

    /// Clear all cached audio
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.audioCache.removeAll()
        }
    }

    // MARK: - Private Methods

    private func fetchAudio(
        text: String,
        voice: KoreanVoice,
        speakingRate: Double
    ) async throws -> Data {
        let requestBody: [String: Any] = [
            "text": text,
            "voiceName": voice.rawValue,
            "speakingRate": speakingRate,
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: apiEndpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 15

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TTSError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw TTSError.requestFailed(httpResponse.statusCode, body)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let success = json["success"] as? Bool, success,
              let responseData = json["data"] as? [String: Any],
              let audioContent = responseData["audioContent"] as? String,
              let audioData = Data(base64Encoded: audioContent)
        else {
            throw TTSError.decodingFailed
        }

        return audioData
    }

    private func playAudio(data: Data) async throws {
        try await MainActor.run {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)

            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
        }

        await MainActor.run {
            isPlaying = true
            audioPlayer?.play()
            HapticFeedback.light.play()
        }
    }

    // MARK: - Cache

    private func getCachedAudio(for key: String) -> Data? {
        cacheQueue.sync {
            audioCache[key]
        }
    }

    private func cacheAudio(_ data: Data, for key: String) {
        cacheQueue.async { [weak self] in
            self?.audioCache[key] = data
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension TTSService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}

// MARK: - Errors

enum TTSError: Error, LocalizedError {
    case invalidResponse
    case requestFailed(Int, String)
    case decodingFailed
    case playbackFailed

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from TTS service."
        case .requestFailed(let code, let message):
            return "TTS request failed (\(code)): \(message)"
        case .decodingFailed:
            return "Failed to decode audio data."
        case .playbackFailed:
            return "Failed to play audio."
        }
    }
}
