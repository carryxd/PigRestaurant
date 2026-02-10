import Foundation
import CoreLocation

struct WeatherCondition {
    enum ConditionType: String {
        case sunny = "晴"
        case cloudy = "多云"
        case rainy = "雨"
        case snowy = "雪"
        case hot = "炎热"
        case cold = "寒冷"
        case normal = "适宜"
    }

    var temperature: Double
    var condition: ConditionType
    var humidity: Double

    var isHot: Bool { temperature > 30 }
    var isCold: Bool { temperature < 10 }
    var isRainy: Bool { condition == .rainy }

    var dietaryPreference: DietarySuggestion {
        if isHot {
            return DietarySuggestion(
                preferHot: false, preferSoup: true, preferLight: true, preferCold: true,
                description: "天气炎热，宜清淡消暑"
            )
        } else if isCold {
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: false, preferCold: false,
                description: "天气寒冷，宜温热进补"
            )
        } else if isRainy {
            return DietarySuggestion(
                preferHot: true, preferSoup: true, preferLight: false, preferCold: false,
                description: "雨天湿冷，宜热汤暖身"
            )
        } else {
            return DietarySuggestion(
                preferHot: true, preferSoup: false, preferLight: false, preferCold: false,
                description: "天气适宜，饮食均衡"
            )
        }
    }

    static func fromSolarTerm(_ term: SolarTerm) -> WeatherCondition {
        let temp = term.estimatedTemperature
        let condition: ConditionType
        if temp > 30 {
            condition = .hot
        } else if temp < 5 {
            condition = .cold
        } else {
            condition = .normal
        }
        return WeatherCondition(temperature: temp, condition: condition, humidity: 0.5)
    }
}

// MARK: - Open-Meteo API（免费，无需 API Key）

private struct OpenMeteoResponse: Decodable {
    struct Current: Decodable {
        let temperature_2m: Double
        let relative_humidity_2m: Double
        let weather_code: Int
    }
    let current: Current
}

private func mapWeatherCode(_ code: Int, temperature: Double) -> WeatherCondition.ConditionType {
    switch code {
    case 0:
        return temperature > 30 ? .hot : (temperature < 5 ? .cold : .sunny)
    case 1, 2, 3:
        return temperature > 30 ? .hot : (temperature < 5 ? .cold : .cloudy)
    case 45, 48:
        return .cloudy
    case 51, 53, 55, 61, 63, 65, 80, 81, 82, 95, 96, 99:
        return .rainy
    case 71, 73, 75, 77, 85, 86:
        return .snowy
    default:
        return temperature > 30 ? .hot : (temperature < 5 ? .cold : .normal)
    }
}

// MARK: - 定位管理

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationDenied = false
    private var continuation: CheckedContinuation<CLLocation?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() async -> CLLocation? {
        let status = manager.authorizationStatus
        if status == .denied || status == .restricted {
            authorizationDenied = true
            return nil
        }

        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            let newStatus = manager.authorizationStatus
            if newStatus == .denied || newStatus == .restricted {
                authorizationDenied = true
                return nil
            }
        }

        return await withCheckedContinuation { cont in
            self.continuation = cont
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let loc = locations.first
        location = loc
        continuation?.resume(returning: loc)
        continuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(returning: nil)
        continuation = nil
    }
}

// MARK: - 天气服务

struct WeatherProvider {
    static func currentWeather(latitude: Double, longitude: Double) async -> WeatherCondition {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&current=temperature_2m,relative_humidity_2m,weather_code&timezone=auto"

        guard let url = URL(string: urlString) else {
            return fallbackWeather()
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                return fallbackWeather()
            }

            let decoded = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
            let temp = decoded.current.temperature_2m
            let humidity = decoded.current.relative_humidity_2m / 100.0
            let condition = mapWeatherCode(decoded.current.weather_code, temperature: temp)

            return WeatherCondition(temperature: temp, condition: condition, humidity: humidity)
        } catch {
            return fallbackWeather()
        }
    }

    static func currentWeather(location: CLLocation?) async -> WeatherCondition {
        let lat = location?.coordinate.latitude ?? 39.9
        let lon = location?.coordinate.longitude ?? 116.4
        return await currentWeather(latitude: lat, longitude: lon)
    }

    static func fallbackWeather() -> WeatherCondition {
        WeatherCondition.fromSolarTerm(SolarTerm.current())
    }
}
