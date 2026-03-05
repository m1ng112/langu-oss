import AVFoundation
import SwiftUI

@Observable
final class AudioRecordingService: NSObject {
    var isRecording = false
    var isPlaying = false
    var currentTime: TimeInterval = 0
    var playbackTime: TimeInterval = 0
    var audioLevel: Float = 0
    var audioLevels: [Float] = Array(repeating: 0, count: 48)

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var playbackTimer: Timer?
    private var recordingURL: URL?

    var formattedTime: String {
        let minutes = Int(currentTime) / 60
        let seconds = Int(currentTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recording_\(Date.now.timeIntervalSince1970).wav")
        recordingURL = url

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000.0,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
        ]

        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()

        isRecording = true
        currentTime = 0
        audioLevels = Array(repeating: 0, count: 48)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.currentTime += 1
        }

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.updateMetering()
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        timer?.invalidate()
        levelTimer?.invalidate()
        timer = nil
        levelTimer = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false)

        return recordingURL
    }

    // MARK: - Playback

    var canPlayback: Bool {
        recordingURL != nil && !isRecording
    }

    var formattedPlaybackTime: String {
        let minutes = Int(playbackTime) / 60
        let seconds = Int(playbackTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var playbackDuration: TimeInterval {
        audioPlayer?.duration ?? 0
    }

    func startPlayback() throws {
        guard let url = recordingURL else { return }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default)
        try session.setActive(true)

        audioPlayer = try AVAudioPlayer(contentsOf: url)
        audioPlayer?.delegate = self
        audioPlayer?.play()

        isPlaying = true
        playbackTime = 0

        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.updatePlaybackTime()
        }

        HapticFeedback.light.play()
    }

    func stopPlayback() {
        audioPlayer?.stop()
        playbackTimer?.invalidate()
        playbackTimer = nil
        isPlaying = false
        playbackTime = 0

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
        } else {
            try? startPlayback()
        }
    }

    private func updatePlaybackTime() {
        playbackTime = audioPlayer?.currentTime ?? 0
    }

    // MARK: - Metering

    private func updateMetering() {
        audioRecorder?.updateMeters()
        let power = audioRecorder?.averagePower(forChannel: 0) ?? -160
        // Normalize: -160..0 dB → 0..1
        let normalized = max(0, (power + 50) / 50)
        audioLevel = normalized

        // Shift levels left and append new
        audioLevels.removeFirst()
        audioLevels.append(normalized)
    }

    // MARK: - Cleanup

    func cleanup() {
        stopRecording()
        stopPlayback()
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioRecordingService: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.playbackTimer?.invalidate()
            self?.playbackTimer = nil
            self?.playbackTime = 0
        }
    }
}
