import SwiftUI

struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @State private var pulseScale: CGFloat = 1.0
    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack {
                // Pulse ring (recording only)
                if isRecording {
                    Circle()
                        .stroke(Color.appRed.opacity(0.3), lineWidth: 4)
                        .scaleEffect(pulseScale)
                        .opacity(2 - Double(pulseScale))
                        .frame(width: 88, height: 88)
                }

                // Outer circle with shadow
                Circle()
                    .fill(isRecording ? Color.appRed.opacity(0.15) : Color.appGreenLight.opacity(0.5))
                    .frame(width: 80, height: 80)
                    .shadow(
                        color: isRecording ? Color.appRed.opacity(0.3) : Color.appGreen.opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )

                // Inner circle
                if isRecording {
                    RoundedRectangle(cornerRadius: AppRadius.sm)
                        .fill(Color.appRed)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.appGreen, .appGreenDark],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 64, height: 64)

                    Image(systemName: "mic.fill")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppAnimation.quick) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(AppAnimation.spring) {
                        isPressed = false
                    }
                }
        )
        .onAppear {
            if isRecording {
                startPulse()
            }
        }
        .onChange(of: isRecording) { _, newValue in
            if newValue {
                startPulse()
                HapticFeedback.medium.play()
            } else {
                pulseScale = 1.0
                HapticFeedback.light.play()
            }
        }
        .accessibilityLabel(isRecording ? AccessibilityLabels.recordingInProgress : AccessibilityLabels.recordButton)
        .accessibilityHint(isRecording ? "Tap to stop recording" : AccessibilityLabels.recordButtonHint)
        .accessibilityAddTraits(.isButton)
    }

    private func startPulse() {
        withAnimation(.easeOut(duration: 1.2).repeatForever(autoreverses: false)) {
            pulseScale = 1.8
        }
    }
}
