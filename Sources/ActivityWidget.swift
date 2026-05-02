import SwiftUI

// MARK: - Main Activity Widget (Circular Rings)

struct ActivityWidget: View {
    @ObservedObject var activityProvider: ActivityProvider
    @State private var showSettings = false

    private let panelCornerRadius: CGFloat = 28

    var body: some View {
        LiquidGlassBackground(cornerRadius: panelCornerRadius) {
            ZStack {
                if showSettings {
                    WidgetSettingsOverlay(
                        showSettings: $showSettings,
                        controller: WidgetWindowController.shared
                    )
                } else {
                    if let activity = activityProvider.currentActivity {
                        ActivityRingsContent(activity: activity)
                    } else if activityProvider.isLoading {
                        LoadingActivityContent()
                    } else {
                        ErrorActivityContent {
                            activityProvider.refresh(force: true)
                        }
                    }
                }

                // Settings button overlay
                if !showSettings {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSettings = true
                                }
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(8)
                                    .background {
                                        Circle()
                                            .fill(.white.opacity(0.12))
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 200, height: 200)
        .onAppear {
            activityProvider.startUpdating()
        }
    }
}

// MARK: - Activity Rings Content

private struct ActivityRingsContent: View {
    let activity: ActivityData

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("Activity")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.8))

            // Rings
            ZStack {
                // Stand ring (outermost)
                RingView(
                    progress: activity.stand.progress,
                    lineWidth: 10,
                    colors: ActivityRing.stand.color
                )
                .frame(width: 130, height: 130)

                // Exercise ring (middle)
                RingView(
                    progress: activity.exercise.progress,
                    lineWidth: 10,
                    colors: ActivityRing.exercise.color
                )
                .frame(width: 106, height: 106)

                // Move ring (innermost)
                RingView(
                    progress: activity.move.progress,
                    lineWidth: 10,
                    colors: ActivityRing.move.color
                )
                .frame(width: 82, height: 82)

                // Center icon
                if activity.allRingsComplete {
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.yellow)
                        .shadow(color: .black.opacity(0.3), radius: 2)
                }
            }

            // Stats
            HStack(spacing: 16) {
                RingStatMini(
                    color: ActivityRing.move.color.start,
                    value: Int(activity.move.current),
                    unit: "CAL"
                )
                RingStatMini(
                    color: ActivityRing.exercise.color.start,
                    value: Int(activity.exercise.current),
                    unit: "MIN"
                )
                RingStatMini(
                    color: ActivityRing.stand.color.start,
                    value: Int(activity.stand.current),
                    unit: "HRS"
                )
            }
        }
        .padding(16)
    }
}

// MARK: - Compact Activity Widget (Horizontal)

struct CompactActivityWidget: View {
    @ObservedObject var activityProvider: ActivityProvider
    @State private var showSettings = false

    private let panelCornerRadius: CGFloat = 22

    var body: some View {
        LiquidGlassBackground(cornerRadius: panelCornerRadius) {
            ZStack {
                if showSettings {
                    WidgetSettingsOverlay(
                        showSettings: $showSettings,
                        controller: WidgetWindowController.shared
                    )
                } else {
                    if let activity = activityProvider.currentActivity {
                        HStack(spacing: 12) {
                            // Mini rings
                            ZStack {
                                RingView(
                                    progress: activity.stand.progress,
                                    lineWidth: 6,
                                    colors: ActivityRing.stand.color
                                )
                                .frame(width: 50, height: 50)

                                RingView(
                                    progress: activity.exercise.progress,
                                    lineWidth: 6,
                                    colors: ActivityRing.exercise.color
                                )
                                .frame(width: 38, height: 38)

                                RingView(
                                    progress: activity.move.progress,
                                    lineWidth: 6,
                                    colors: ActivityRing.move.color
                                )
                                .frame(width: 26, height: 26)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Activity")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))

                                HStack(spacing: 12) {
                                    CompactStat(value: Int(activity.move.current), unit: "cal")
                                    CompactStat(value: Int(activity.exercise.current), unit: "min")
                                    CompactStat(value: Int(activity.stand.current), unit: "hrs")
                                }
                            }

                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    } else {
                        HStack {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white.opacity(0.7))
                                .scaleEffect(0.8)
                            Spacer()
                        }
                        .padding()
                    }
                }

                // Settings button
                if !showSettings {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSettings = true
                                }
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(6)
                                    .background {
                                        Circle()
                                            .fill(.white.opacity(0.12))
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(6)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 220, height: 80)
        .onAppear {
            activityProvider.startUpdating()
        }
    }
}

// MARK: - Circular Activity Widget (Mini)

struct CircularActivityWidget: View {
    @ObservedObject var activityProvider: ActivityProvider
    @State private var showSettings = false

    var body: some View {
        LiquidGlassBackground(cornerRadius: 45) {
            ZStack {
                if showSettings {
                    WidgetSettingsOverlay(
                        showSettings: $showSettings,
                        controller: WidgetWindowController.shared
                    )
                } else {
                    if let activity = activityProvider.currentActivity {
                        ZStack {
                            // Mini rings
                            RingView(
                                progress: activity.stand.progress,
                                lineWidth: 5,
                                colors: ActivityRing.stand.color
                            )
                            .frame(width: 60, height: 60)

                            RingView(
                                progress: activity.exercise.progress,
                                lineWidth: 5,
                                colors: ActivityRing.exercise.color
                            )
                            .frame(width: 48, height: 48)

                            RingView(
                                progress: activity.move.progress,
                                lineWidth: 5,
                                colors: ActivityRing.move.color
                            )
                            .frame(width: 36, height: 36)

                            // Center percentage
                            if activity.allRingsComplete {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.yellow)
                            }
                        }
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white.opacity(0.7))
                            .scaleEffect(0.7)
                    }
                }

                // Settings button
                if !showSettings {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSettings = true
                                }
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 9))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(5)
                                    .background {
                                        Circle()
                                            .fill(.white.opacity(0.12))
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(4)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 90, height: 90)
        .onAppear {
            activityProvider.startUpdating()
        }
    }
}

// MARK: - Detailed Activity Widget

struct DetailedActivityWidget: View {
    @ObservedObject var activityProvider: ActivityProvider
    @State private var showSettings = false

    private let panelCornerRadius: CGFloat = 32

    var body: some View {
        LiquidGlassBackground(cornerRadius: panelCornerRadius) {
            ZStack {
                if showSettings {
                    WidgetSettingsOverlay(
                        showSettings: $showSettings,
                        controller: WidgetWindowController.shared
                    )
                } else {
                    if let activity = activityProvider.currentActivity {
                        HStack(spacing: 24) {
                            // Left side - Rings
                            ZStack {
                                RingView(
                                    progress: activity.stand.progress,
                                    lineWidth: 12,
                                    colors: ActivityRing.stand.color
                                )
                                .frame(width: 120, height: 120)

                                RingView(
                                    progress: activity.exercise.progress,
                                    lineWidth: 12,
                                    colors: ActivityRing.exercise.color
                                )
                                .frame(width: 94, height: 94)

                                RingView(
                                    progress: activity.move.progress,
                                    lineWidth: 12,
                                    colors: ActivityRing.move.color
                                )
                                .frame(width: 68, height: 68)

                                if activity.allRingsComplete {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 24))
                                        .foregroundStyle(.yellow)
                                        .shadow(color: .black.opacity(0.3), radius: 3)
                                }
                            }

                            // Right side - Details
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Activity")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.95))

                                Rectangle()
                                    .fill(.white.opacity(0.15))
                                    .frame(height: 0.5)

                                VStack(alignment: .leading, spacing: 8) {
                                    DetailedRingStat(
                                        icon: ActivityRing.move.icon,
                                        color: ActivityRing.move.color.start,
                                        title: "Move",
                                        current: Int(activity.move.current),
                                        goal: Int(activity.move.goal),
                                        unit: "CAL"
                                    )

                                    DetailedRingStat(
                                        icon: ActivityRing.exercise.icon,
                                        color: ActivityRing.exercise.color.start,
                                        title: "Exercise",
                                        current: Int(activity.exercise.current),
                                        goal: Int(activity.exercise.goal),
                                        unit: "MIN"
                                    )

                                    DetailedRingStat(
                                        icon: ActivityRing.stand.icon,
                                        color: ActivityRing.stand.color.start,
                                        title: "Stand",
                                        current: Int(activity.stand.current),
                                        goal: Int(activity.stand.goal),
                                        unit: "HRS"
                                    )
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(24)
                    } else {
                        LoadingActivityContent()
                    }
                }

                // Settings button
                if !showSettings {
                    VStack {
                        HStack {
                            Spacer()
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    showSettings = true
                                }
                            } label: {
                                Image(systemName: "gear")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .padding(8)
                                    .background {
                                        Circle()
                                            .fill(.white.opacity(0.12))
                                    }
                            }
                            .buttonStyle(.plain)
                            .padding(10)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(width: 340, height: 180)
        .onAppear {
            activityProvider.startUpdating()
        }
    }
}

// MARK: - Ring View

private struct RingView: View {
    let progress: Double
    let lineWidth: CGFloat
    let colors: (start: String, end: String)

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(.white.opacity(0.1), lineWidth: lineWidth)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            Color(hex: colors.start),
                            Color(hex: colors.end)
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: Color(hex: colors.start).opacity(0.4), radius: 4)
        }
    }
}

// MARK: - Supporting Views

private struct RingStatMini: View {
    let color: String
    let value: Int
    let unit: String

    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: color))

            Text(unit)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

private struct CompactStat: View {
    let value: Int
    let unit: String

    var body: some View {
        HStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Text(unit)
                .font(.system(size: 9, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))
        }
    }
}

private struct DetailedRingStat: View {
    let icon: String
    let color: String
    let title: String
    let current: Int
    let goal: Int
    let unit: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundStyle(Color(hex: color))
                .frame(width: 18)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                HStack(spacing: 3) {
                    Text("\(current)")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("/")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.4))
                    Text("\(goal)")
                        .font(.system(size: 11, weight: .regular, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(unit)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }
}

// MARK: - Loading Content

private struct LoadingActivityContent: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.7))

            Text("Loading activity...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Content

private struct ErrorActivityContent: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow.opacity(0.9))

            Text("Unable to load activity")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

            Text("Check HealthKit permissions")
                .font(.system(size: 10, weight: .regular))
                .foregroundStyle(.white.opacity(0.5))

            Button("Retry") {
                onRetry()
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background {
                Capsule()
                    .fill(.white.opacity(0.15))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
