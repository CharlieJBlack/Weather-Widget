import SwiftUI

// MARK: - Main Weather Widget (Apple Music Panel Style)

struct WeatherWidget: View {
    @ObservedObject var weatherProvider: WeatherProvider
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
                    if let weather = weatherProvider.currentWeather {
                        WeatherPanelContent(weather: weather)
                    } else if weatherProvider.isLoading {
                        LoadingContent()
                    } else {
                        ErrorContent {
                            weatherProvider.refresh(force: true)
                        }
                    }
                }

                // Settings button overlay (inside glass)
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
            weatherProvider.startUpdating()
        }
    }
}

// MARK: - Weather Panel Content

private struct WeatherPanelContent: View {
    let weather: WeatherData

    var body: some View {
        VStack(spacing: 8) {
            // Location
            Text(weather.location)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))
                .lineLimit(1)

            // Weather Icon
            Image(systemName: weather.condition.sfSymbol)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 52))
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

            // Temperature
            HStack(alignment: .top, spacing: 2) {
                Text(weather.temperatureString)
                    .font(.system(size: 52, weight: .thin, design: .rounded))
                Text("\u{00B0}")
                    .font(.system(size: 24, weight: .thin))
                    .offset(y: 8)
            }
            .foregroundStyle(.white)

            // Condition
            Text(weather.condition.description)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))

            // High/Low
            Text(weather.highLowString)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(16)
    }
}

// MARK: - Compact Weather Widget (Horizontal Panel Style)

struct CompactWeatherWidget: View {
    @ObservedObject var weatherProvider: WeatherProvider
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
            if let weather = weatherProvider.currentWeather {
                HStack(spacing: 14) {
                    // Weather Icon
                    Image(systemName: weather.condition.sfSymbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 36))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        // Temperature
                        HStack(alignment: .top, spacing: 1) {
                            Text(weather.temperatureString)
                                .font(.system(size: 32, weight: .light, design: .rounded))
                            Text("\u{00B0}")
                                .font(.system(size: 14, weight: .light))
                                .offset(y: 4)
                        }
                        .foregroundStyle(.white)

                        // Location
                        Text(weather.location)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.6))
                            .lineLimit(1)
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
        .frame(width: 180, height: 80)
        .onAppear {
            weatherProvider.startUpdating()
        }
    }
}

// MARK: - Circular Weather Widget

struct CircularWeatherWidget: View {
    @ObservedObject var weatherProvider: WeatherProvider
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
            if let weather = weatherProvider.currentWeather {
                VStack(spacing: 4) {
                    Image(systemName: weather.condition.sfSymbol)
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 28))

                    HStack(alignment: .top, spacing: 1) {
                        Text(weather.temperatureString)
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                        Text("\u{00B0}")
                            .font(.system(size: 10, weight: .light))
                            .offset(y: 2)
                    }
                    .foregroundStyle(.white)
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
            weatherProvider.startUpdating()
        }
    }
}

// MARK: - Detailed Weather Widget (Music Panel Style)

struct DetailedWeatherWidget: View {
    @ObservedObject var weatherProvider: WeatherProvider
    @State private var showSettings = false

    private let panelCornerRadius: CGFloat = 32

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()

    var body: some View {
        LiquidGlassBackground(cornerRadius: panelCornerRadius) {
            ZStack {
                if showSettings {
                    WidgetSettingsOverlay(
                        showSettings: $showSettings,
                        controller: WidgetWindowController.shared
                    )
                } else {
            if let weather = weatherProvider.currentWeather {
                HStack(spacing: 20) {
                    // Left side - Icon and Temperature
                    VStack(spacing: 6) {
                        Image(systemName: weather.condition.sfSymbol)
                            .symbolRenderingMode(.multicolor)
                            .font(.system(size: 56))
                            .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)

                        HStack(alignment: .top, spacing: 2) {
                            Text(weather.temperatureString)
                                .font(.system(size: 48, weight: .thin, design: .rounded))
                            Text("\u{00B0}")
                                .font(.system(size: 20, weight: .thin))
                                .offset(y: 6)
                        }
                        .foregroundStyle(.white)
                    }
                    .frame(width: 120)

                    // Right side - Details
                    VStack(alignment: .leading, spacing: 10) {
                        // Location and condition
                        VStack(alignment: .leading, spacing: 2) {
                            Text(weather.location)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.95))
                                .lineLimit(1)

                            Text(weather.condition.description)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.7))
                        }

                        // Divider
                        Rectangle()
                            .fill(.white.opacity(0.15))
                            .frame(height: 0.5)

                        // Details grid
                        VStack(alignment: .leading, spacing: 6) {
                            DetailRow(icon: "thermometer.medium", value: weather.highLowString)
                            DetailRow(icon: "humidity.fill", value: "\(weather.humidity)%")
                            DetailRow(icon: "wind", value: "\(Int(weather.windSpeed)) km/h")

                            if let sunrise = weather.sunriseTime {
                                DetailRow(icon: "sunrise.fill", value: timeFormatter.string(from: sunrise))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(24)
            } else {
                LoadingContent()
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
            weatherProvider.startUpdating()
        }
    }
}

// MARK: - Detail Row

private struct DetailRow: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 14)

            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
        }
    }
}

// MARK: - Loading Content

private struct LoadingContent: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white.opacity(0.7))

            Text("Loading...")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error Content

private struct ErrorContent: View {
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.yellow.opacity(0.9))

            Text("Unable to load weather")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.7))

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
