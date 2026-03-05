import SwiftUI

struct WaveformView: View {
    let isRecording: Bool
    let audioLevels: [Float]

    private let barCount = 48
    private let barGap: CGFloat = 3

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let totalGaps = CGFloat(barCount - 1) * barGap
                let barWidth = (size.width - totalGaps) / CGFloat(barCount)
                let maxHeight = size.height
                let time = timeline.date.timeIntervalSinceReferenceDate

                for i in 0..<barCount {
                    let x = CGFloat(i) * (barWidth + barGap)
                    let level: CGFloat

                    if isRecording {
                        let audioVal = CGFloat(i < audioLevels.count ? audioLevels[i] : 0)
                        // Add organic wave motion
                        let wave1 = sin(time * 3.0 + Double(i) * 0.3) * 0.15
                        let wave2 = sin(time * 1.7 + Double(i) * 0.5) * 0.1
                        let wave3 = sin(time * 5.0 + Double(i) * 0.2) * 0.05
                        level = max(0.08, min(1.0, audioVal + CGFloat(wave1 + wave2 + wave3)))
                    } else {
                        // Idle: gentle ambient wave
                        let wave = sin(time * 1.2 + Double(i) * 0.15) * 0.03
                        level = 0.08 + CGFloat(wave)
                    }

                    let barHeight = max(4, level * maxHeight)
                    let y = (maxHeight - barHeight) / 2

                    let rect = RoundedRectangle(cornerRadius: barWidth / 2)
                        .path(in: CGRect(x: x, y: y, width: barWidth, height: barHeight))

                    let color = isRecording ? Color.appGreen : Color.appTextMuted.opacity(0.3)
                    context.fill(rect, with: .color(color))
                }
            }
        }
        .frame(height: 64)
    }
}
