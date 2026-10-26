import PetalKit
import SwiftUI

public struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("petalTheme") private var selectedTheme: String = PetalTheme.light.rawValue

    @State private var currentStep: Int = 0
    public var onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Mascot header
            MascotFaceView(mood: .celebrating, tint: .orange, size: 40)
                .padding(.top, 16)

            Text("Welcome to Petal")
                .font(.system(size: 22, weight: .bold, design: .rounded))

            TabView(selection: $currentStep) {
                // Card 1: Theme
                themeStepCard.tag(0)

                // Card 2: Permissions
                permissionsStepCard.tag(1)

                // Card 3: Google Drive
                driveStepCard.tag(2)
            }
            .tabViewStyle(.automatic)
            .frame(height: 220)

            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                if currentStep < 2 {
                    Button("Continue") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button("Get Started") {
                        hasCompletedOnboarding = true
                        onFinish()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .frame(width: 440, height: 380)
        .background(.ultraThinMaterial)
    }

    private var themeStepCard: some View {
        VStack(spacing: 12) {
            Text("1. Choose your desk theme")
                .font(.headline)

            HStack(spacing: 16) {
                ForEach(PetalTheme.allCases) { theme in
                    Button(action: { selectedTheme = theme.rawValue }) {
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(theme == .dark ? Color(hex: "#282A30") : Color(hex: "#FFF3B0"))
                                .frame(width: 70, height: 50)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(
                                            selectedTheme == theme.rawValue ? Color.blue : Color.clear,
                                            lineWidth: 2
                                        )
                                )
                            Text(theme.rawValue)
                                .font(.caption).bold()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var permissionsStepCard: some View {
        VStack(spacing: 12) {
            Text("2. Enable Reminders & Voice")
                .font(.headline)
            Text("Petal uses macOS notifications for alarms and microphone for quick voice notes.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Grant Notification & Mic Access") {
                MacNotificationManager.shared.requestAuthorization()
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal, 20)
    }

    private var driveStepCard: some View {
        VStack(spacing: 12) {
            Text("3. Google Drive Backup")
                .font(.headline)
            Text("Every note is safely mirrored to your private Google Drive 'Petal Backup' folder.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button("Connect Google Drive") {
                    hasCompletedOnboarding = true
                    onFinish()
                }
                .buttonStyle(.borderedProminent)

                Button("Skip for now") {
                    hasCompletedOnboarding = true
                    onFinish()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 20)
    }
}
