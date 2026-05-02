import SwiftUI
import AppKit

@main
struct LockScreenWeatherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }

        MenuBarExtra("Weather Widget", systemImage: "cloud.sun.fill") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize managers
        _ = LockScreenMonitor.shared
        _ = WidgetWindowController.shared
        _ = WeatherProvider.shared
        _ = ActivityProvider.shared

        // Start data updates
        WeatherProvider.shared.startUpdating()
        ActivityProvider.shared.startUpdating()

        // Hide dock icon (menu bar app)
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationWillTerminate(_ notification: Notification) {
        WidgetWindowController.shared.hideWidget()
    }
}

// MARK: - Menu Bar View

struct MenuBarView: View {
    @ObservedObject var weatherProvider = WeatherProvider.shared
    @ObservedObject var activityProvider = ActivityProvider.shared
    @ObservedObject var widgetController = WidgetWindowController.shared

    var body: some View {
        VStack(spacing: 0) {
            // Widget Preview
            if widgetController.widgetType == .weather {
                if let weather = weatherProvider.currentWeather {
                    WeatherMenuPreview(weather: weather)
                        .padding()
                } else if weatherProvider.isLoading {
                    ProgressView("Loading weather...")
                        .padding()
                } else {
                    Text("Unable to load weather")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            } else {
                if let activity = activityProvider.currentActivity {
                    ActivityMenuPreview(activity: activity)
                        .padding()
                } else if activityProvider.isLoading {
                    ProgressView("Loading activity...")
                        .padding()
                } else {
                    Text("Unable to load activity")
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }

            Divider()

            // Controls
            VStack(spacing: 8) {
                // Widget toggle
                Button {
                    widgetController.toggleWidget()
                } label: {
                    HStack {
                        Image(systemName: widgetController.isVisible ? "eye.slash" : "eye")
                        Text(widgetController.isVisible ? "Hide Widget" : "Show Widget")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)

                // Widget type picker
                Menu {
                    ForEach(WidgetWindowController.WidgetType.allCases, id: \.rawValue) { type in
                        Button(type.rawValue) {
                            widgetController.setWidgetType(type)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: widgetController.widgetType == .weather ? "cloud.sun" : "figure.run")
                        Text("Type: \(widgetController.widgetType.rawValue)")
                        Spacer()
                    }
                }

                // Position picker
                Menu {
                    ForEach(WidgetWindowController.WidgetPosition.allCases, id: \.rawValue) { position in
                        Button(position.rawValue) {
                            widgetController.setPosition(position)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text("Position: \(widgetController.widgetPosition.rawValue)")
                        Spacer()
                    }
                }

                // Style picker
                Menu {
                    ForEach(WidgetWindowController.WidgetStyle.allCases, id: \.rawValue) { style in
                        Button(style.rawValue) {
                            widgetController.setStyle(style)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "square.on.square")
                        Text("Style: \(widgetController.widgetStyle.rawValue)")
                        Spacer()
                    }
                }

                // Refresh
                Button {
                    if widgetController.widgetType == .weather {
                        weatherProvider.refresh(force: true)
                    } else {
                        activityProvider.refresh(force: true)
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh \(widgetController.widgetType.rawValue)")
                        Spacer()
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Footer
            HStack {
                Button("Settings...") {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .frame(width: 280)
    }
}

// MARK: - Weather Menu Preview

struct WeatherMenuPreview: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: weather.condition.sfSymbol)
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 36))

            VStack(alignment: .leading, spacing: 2) {
                Text(weather.location)
                    .font(.headline)

                HStack(alignment: .top, spacing: 2) {
                    Text(weather.temperatureString)
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                    Text("\u{00B0}")
                        .font(.system(size: 14, weight: .light))
                        .offset(y: 2)
                }

                Text(weather.condition.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(weather.highLowString)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Activity Menu Preview

struct ActivityMenuPreview: View {
    let activity: ActivityData

    var body: some View {
        HStack(spacing: 12) {
            // Mini rings
            ZStack {
                Circle()
                    .trim(from: 0, to: activity.stand.progress)
                    .stroke(Color(hex: ActivityRing.stand.color.start), lineWidth: 4)
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: 0, to: activity.exercise.progress)
                    .stroke(Color(hex: ActivityRing.exercise.color.start), lineWidth: 4)
                    .frame(width: 30, height: 30)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: 0, to: activity.move.progress)
                    .stroke(Color(hex: ActivityRing.move.color.start), lineWidth: 4)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text("Activity Rings")
                    .font(.headline)

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Move")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(activity.move.current))/\(Int(activity.move.goal))")
                            .font(.caption)
                            .foregroundStyle(Color(hex: ActivityRing.move.color.start))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Exercise")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(activity.exercise.current))/\(Int(activity.exercise.goal))")
                            .font(.caption)
                            .foregroundStyle(Color(hex: ActivityRing.exercise.color.start))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Stand")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text("\(Int(activity.stand.current))/\(Int(activity.stand.goal))")
                            .font(.caption)
                            .foregroundStyle(Color(hex: ActivityRing.stand.color.start))
                    }
                }
            }
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var widgetController = WidgetWindowController.shared
    @AppStorage("launchAtLogin") var launchAtLogin = false
    @AppStorage("showOnLockScreen") var showOnLockScreen = true
    @AppStorage("showOnScreenSaver") var showOnScreenSaver = true
    @AppStorage("temperatureUnit") var temperatureUnit = "celsius"

    var body: some View {
        TabView {
            GeneralSettingsView(
                launchAtLogin: $launchAtLogin,
                showOnLockScreen: $showOnLockScreen,
                showOnScreenSaver: $showOnScreenSaver
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }

            AppearanceSettingsView(widgetController: widgetController)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            WeatherSettingsView(temperatureUnit: $temperatureUnit)
                .tabItem {
                    Label("Weather", systemImage: "cloud.sun")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @Binding var launchAtLogin: Bool
    @Binding var showOnLockScreen: Bool
    @Binding var showOnScreenSaver: Bool

    var body: some View {
        Form {
            Section {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show widget on lock screen", isOn: $showOnLockScreen)
                Toggle("Show widget on screen saver", isOn: $showOnScreenSaver)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Appearance Settings

struct AppearanceSettingsView: View {
    @ObservedObject var widgetController: WidgetWindowController

    var body: some View {
        Form {
            Section("Widget Style") {
                Picker("Style", selection: Binding(
                    get: { widgetController.widgetStyle },
                    set: { widgetController.setStyle($0) }
                )) {
                    ForEach(WidgetWindowController.WidgetStyle.allCases, id: \.rawValue) { style in
                        Text(style.rawValue).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Position") {
                Picker("Position", selection: Binding(
                    get: { widgetController.widgetPosition },
                    set: { widgetController.setPosition($0) }
                )) {
                    ForEach(WidgetWindowController.WidgetPosition.allCases, id: \.rawValue) { position in
                        Text(position.rawValue).tag(position)
                    }
                }
            }

            Section {
                Button("Preview Widget") {
                    widgetController.showWidget()
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Weather Settings

struct WeatherSettingsView: View {
    @Binding var temperatureUnit: String

    var body: some View {
        Form {
            Section("Temperature") {
                Picker("Unit", selection: $temperatureUnit) {
                    Text("Celsius (\u{00B0}C)").tag("celsius")
                    Text("Fahrenheit (\u{00B0}F)").tag("fahrenheit")
                }
            }

            Section("Location") {
                HStack {
                    Text("Current: \(WeatherProvider.shared.locationName)")
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button("Refresh") {
                        WeatherProvider.shared.refresh(force: true)
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cloud.sun.fill")
                .symbolRenderingMode(.multicolor)
                .font(.system(size: 64))

            Text("Lock Screen Weather")
                .font(.title)
                .fontWeight(.semibold)

            Text("Version 1.0")
                .foregroundStyle(.secondary)

            Text("A beautiful weather widget for your Mac lock screen with liquid glass aesthetics.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)

            Spacer()

            Text("Inspired by Atoll & Alcove")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}
