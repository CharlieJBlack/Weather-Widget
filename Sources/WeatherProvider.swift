import Foundation
import CoreLocation
import Combine

// MARK: - Weather Provider

@MainActor
class WeatherProvider: NSObject, ObservableObject {
    static let shared = WeatherProvider()

    @Published var currentWeather: WeatherData?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var locationName: String = "Loading..."

    private let locationManager = CLLocationManager()
    private var lastFetchTime: Date?
    private let minimumRefreshInterval: TimeInterval = 300 // 5 minutes

    private var currentLocation: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func startUpdating() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            errorMessage = "Location access denied"
            // Use a default location (San Francisco)
            fetchWeather(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
        @unknown default:
            break
        }
    }

    func refresh(force: Bool = false) {
        if !force, let lastFetch = lastFetchTime {
            let elapsed = Date().timeIntervalSince(lastFetch)
            if elapsed < minimumRefreshInterval {
                return
            }
        }

        if let location = currentLocation {
            Task {
                await fetchWeatherForLocation(location)
            }
        } else {
            locationManager.requestLocation()
        }
    }

    private func fetchWeatherForLocation(_ location: CLLocation) async {
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude

        // Get location name via reverse geocoding
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            let name = placemarks.first?.locality ?? placemarks.first?.administrativeArea ?? "Unknown"
            fetchWeather(latitude: latitude, longitude: longitude, locationName: name)
        } catch {
            fetchWeather(latitude: latitude, longitude: longitude, locationName: "Unknown")
        }
    }

    private func fetchWeather(latitude: Double, longitude: Double, locationName: String) {
        isLoading = true
        errorMessage = nil
        self.locationName = locationName

        let urlString = """
        https://api.open-meteo.com/v1/forecast?\
        latitude=\(latitude)&longitude=\(longitude)\
        &current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,is_day\
        &daily=temperature_2m_max,temperature_2m_min,sunrise,sunset\
        &timezone=auto\
        &forecast_days=1
        """

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)

                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]

                let sunrise = response.daily.sunrise.first.flatMap { dateFormatter.date(from: $0) }
                let sunset = response.daily.sunset.first.flatMap { dateFormatter.date(from: $0) }

                let weather = WeatherData(
                    temperature: response.current.temperature_2m,
                    temperatureMin: response.daily.temperature_2m_min.first ?? response.current.temperature_2m,
                    temperatureMax: response.daily.temperature_2m_max.first ?? response.current.temperature_2m,
                    weatherCode: response.current.weather_code,
                    humidity: response.current.relative_humidity_2m,
                    windSpeed: response.current.wind_speed_10m,
                    isDay: response.current.is_day == 1,
                    location: locationName,
                    sunriseTime: sunrise,
                    sunsetTime: sunset
                )

                await MainActor.run {
                    self.currentWeather = weather
                    self.isLoading = false
                    self.lastFetchTime = Date()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to fetch weather: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherProvider: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        Task { @MainActor in
            self.currentLocation = location
            await self.fetchWeatherForLocation(location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = "Location error: \(error.localizedDescription)"
            // Fallback to default location
            self.fetchWeather(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedAlways, .authorizedWhenInUse:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.errorMessage = "Location access denied"
                self.fetchWeather(latitude: 37.7749, longitude: -122.4194, locationName: "San Francisco")
            default:
                break
            }
        }
    }
}
