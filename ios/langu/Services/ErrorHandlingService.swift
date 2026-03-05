import Foundation
import SwiftUI

// MARK: - App Error Types

enum AppError: LocalizedError, Identifiable {
    case network(NetworkError)
    case audio(AudioError)
    case data(DataError)
    case generic(String)

    var id: String {
        switch self {
        case .network(let e): return "network_\(e.rawValue)"
        case .audio(let e): return "audio_\(e.rawValue)"
        case .data(let e): return "data_\(e.rawValue)"
        case .generic(let msg): return "generic_\(msg.hashValue)"
        }
    }

    var errorDescription: String? {
        switch self {
        case .network(let error): return error.message
        case .audio(let error): return error.message
        case .data(let error): return error.message
        case .generic(let message): return message
        }
    }

    var icon: String {
        switch self {
        case .network: return "wifi.slash"
        case .audio: return "mic.slash"
        case .data: return "exclamationmark.triangle"
        case .generic: return "exclamationmark.circle"
        }
    }

    var isRetryable: Bool {
        switch self {
        case .network(let e): return e.isRetryable
        case .audio: return true
        case .data: return false
        case .generic: return false
        }
    }

    var recoveryAction: RecoveryAction? {
        switch self {
        case .network(let e) where e == .noConnection:
            return .checkConnection
        case .audio(let e) where e == .permissionDenied:
            return .openSettings
        case .audio(let e) where e == .recordingFailed:
            return .retry
        case .network:
            return .retry
        default:
            return nil
        }
    }
}

enum NetworkError: String {
    case noConnection
    case timeout
    case serverError
    case invalidResponse
    case rateLimited

    var message: String {
        switch self {
        case .noConnection: return "No internet connection. Please check your network and try again."
        case .timeout: return "Request timed out. Please try again."
        case .serverError: return "Server error. Please try again later."
        case .invalidResponse: return "Invalid response from server."
        case .rateLimited: return "Too many requests. Please wait a moment and try again."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noConnection, .timeout, .serverError, .rateLimited: return true
        case .invalidResponse: return false
        }
    }
}

enum AudioError: String {
    case permissionDenied
    case recordingFailed
    case audioTooShort
    case noSpeechDetected
    case processingFailed

    var message: String {
        switch self {
        case .permissionDenied: return "Microphone access is required. Please enable it in Settings."
        case .recordingFailed: return "Failed to start recording. Please try again."
        case .audioTooShort: return "Recording too short. Hold the button longer."
        case .noSpeechDetected: return "No speech detected. Please speak clearly and try again."
        case .processingFailed: return "Failed to process audio. Please try again."
        }
    }
}

enum DataError: String {
    case saveFailed
    case loadFailed
    case corrupted

    var message: String {
        switch self {
        case .saveFailed: return "Failed to save data. Please try again."
        case .loadFailed: return "Failed to load data."
        case .corrupted: return "Data appears to be corrupted."
        }
    }
}

enum RecoveryAction {
    case retry
    case openSettings
    case checkConnection
    case dismiss

    var title: String {
        switch self {
        case .retry: return "Try Again"
        case .openSettings: return "Open Settings"
        case .checkConnection: return "OK"
        case .dismiss: return "Dismiss"
        }
    }

    var icon: String {
        switch self {
        case .retry: return "arrow.clockwise"
        case .openSettings: return "gear"
        case .checkConnection: return "wifi"
        case .dismiss: return "xmark"
        }
    }
}

// MARK: - Error Handling Service

@Observable
final class ErrorHandlingService {
    var currentError: AppError?
    var showingError = false

    private var retryAction: (() async -> Void)?

    func handle(_ error: Error, retryAction: (() async -> Void)? = nil) {
        self.retryAction = retryAction

        // Convert to AppError if needed
        if let appError = error as? AppError {
            currentError = appError
        } else if let assessmentError = error as? SpeechAssessmentService.AssessmentError {
            currentError = mapAssessmentError(assessmentError)
        } else {
            currentError = .generic(error.localizedDescription)
        }

        withAnimation(.spring(response: 0.3)) {
            showingError = true
        }
    }

    func dismiss() {
        withAnimation(.spring(response: 0.3)) {
            showingError = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentError = nil
            self.retryAction = nil
        }
    }

    func performRecovery() {
        guard let error = currentError, let action = error.recoveryAction else {
            dismiss()
            return
        }

        switch action {
        case .retry:
            dismiss()
            if let retry = retryAction {
                Task { await retry() }
            }
        case .openSettings:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
            dismiss()
        case .checkConnection, .dismiss:
            dismiss()
        }
    }

    private func mapAssessmentError(_ error: SpeechAssessmentService.AssessmentError) -> AppError {
        switch error {
        case .audioReadFailed, .audioTooShort:
            return .audio(.audioTooShort)
        case .networkError:
            return .network(.noConnection)
        case .requestFailed(let code, _):
            if code == 429 {
                return .network(.rateLimited)
            } else if code >= 500 {
                return .network(.serverError)
            }
            return .network(.invalidResponse)
        case .decodingFailed:
            return .network(.invalidResponse)
        case .noSpeechDetected:
            return .audio(.noSpeechDetected)
        }
    }
}
