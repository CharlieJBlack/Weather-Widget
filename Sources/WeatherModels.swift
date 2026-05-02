import Foundation

// MARK: - Weather Data Models

struct WeatherData: Codable {
    let temperature: Double
    let temperatureMin: Double
    let temperatureMax: Double
    let weatherCode: Int
    let humidity: Int
    let windSpeed: Double
    let isDay: Bool
    let location: String
    let sunriseTime: Date?
    let sunsetTime: Date?

    var condition: WeatherCondition {
        WeatherCondition.from(code: weatherCode, isDay: isDay)
    }

    var temperatureString: String {
        "\(Int(round(temperature)))"
    }

    var highLowString: String {
        "H:\(Int(round(temperatureMax))) L:\(Int(round(temperatureMin)))"
    }
}

// MARK: - Weather Condition Mapping

enum WeatherCondition: String {
    case clearDay = "sun.max.fill"
    case clearNight = "moon.stars.fill"
    case partlyCloudyDay = "cloud.sun.fill"
    case partlyCloudyNight = "cloud.moon.fill"
    case cloudy = "cloud.fill"
    case foggy = "cloud.fog.fill"
    case drizzle = "cloud.drizzle.fill"
    case rain = "cloud.rain.fill"
    case heavyRain = "cloud.heavyrain.fill"
    case freezingRain = "cloud.sleet.fill"
    case snow = "cloud.snow.fill"
    case heavySnow = "snowflake"
    case thunderstorm = "cloud.bolt.rain.fill"
    case hail = "cloud.hail.fill"
    case unknown = "questionmark.circle.fill"

    var sfSymbol: String { rawValue }

    var description: String {
        switch self {
        case .clearDay: return "Clear"
        case .clearNight: return "Clear"
        case .partlyCloudyDay, .partlyCloudyNight: return "Partly Cloudy"
        case .cloudy: return "Cloudy"
        case .foggy: return "Foggy"
        case .drizzle: return "Drizzle"
        case .rain: return "Rain"
        case .heavyRain: return "Heavy Rain"
        case .freezingRain: return "Freezing Rain"
        case .snow: return "Snow"
        case .heavySnow: return "Heavy Snow"
        case .thunderstorm: return "Thunderstorm"
        case .hail: return "Hail"
        case .unknown: return "Unknown"
        }
    }

    // Maps WMO weather codes to conditions
    // Reference: https://open-meteo.com/en/docs
    static func from(code: Int, isDay: Bool) -> WeatherCondition {
        switch code {
        case 0:
            return isDay ? .clearDay : .clearNight
        case 1, 2:
            return isDay ? .partlyCloudyDay : .partlyCloudyNight
        case 3:
            return .cloudy
        case 45, 48:
            return .foggy
        case 51, 53, 55:
            return .drizzle
        case 56, 57:
            return .freezingRain
        case 61, 63:
            return .rain
        case 65:
            return .heavyRain
        case 66, 67:
            return .freezingRain
        case 71, 73:
            return .snow
        case 75, 77:
            return .heavySnow
        case 80, 81:
            return .rain
        case 82:
            return .heavyRain
        case 85, 86:
            return .snow
        case 95:
            return .thunderstorm
        case 96, 99:
            return .hail
        default:
            return .unknown
        }
    }
}

// MARK: - Open-Meteo API Response Models

struct OpenMeteoResponse: Codable {
    let latitude: Double
    let longitude: Double
    let current: CurrentWeather
    let daily: DailyWeather

    struct CurrentWeather: Codable {
        let temperature_2m: Double
        let relative_humidity_2m: Int
        let weather_code: Int
        let wind_speed_10m: Double
        let is_day: Int
    }

    struct DailyWeather: Codable {
        let temperature_2m_max: [Double]
        let temperature_2m_min: [Double]
        let sunrise: [String]
        let sunset: [String]
    }
}

// MARK: - Location Models

struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?

    struct GeocodingResult: Codable {
        let name: String
        let latitude: Double
        let longitude: Double
        let country: String?
        let admin1: String? // State/Province
    }
}

// MARK: - Reverse Geocoding (for current location)

struct ReverseGeocodingResponse: Codable {
    let address: Address?

    struct Address: Codable {
        let city: String?
        let town: String?
        let village: String?
        let county: String?
        let state: String?
        let country: String?

        var displayName: String {
            city ?? town ?? village ?? county ?? state ?? "Unknown"
        }
    }
}
