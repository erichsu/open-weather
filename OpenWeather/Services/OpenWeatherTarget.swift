//
//  OpenWeatherTarget.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/28.
//

import Foundation
import MoyaSugar

let API = MoyaSugarProvider<OpenWeatherTarget>()

// MARK: - OpenWeatherTarget

enum OpenWeatherTarget: SugarTargetType {
    case forecast(id: Int)
    case weatherOfZip(Int, String)
    case weatherOfCityName(String)

    // MARK: Internal

    static let apiKey = "95d190a434083879a6398aafd54d9e73"

    var route: Route {
        switch self {
        case .forecast: return .get("/forecast")
        case .weatherOfZip: return .get("/weather")
        case .weatherOfCityName: return .get("/weather")
        }
    }

    var parameters: Parameters? {
        switch self {
        case .forecast(let id):
            return URLEncoding() => [
                "id": id,
                "appid": OpenWeatherTarget.apiKey,
                "lang": Locale.current.identifier
            ]
        case let .weatherOfZip(zip, country):
            return URLEncoding() => [
                "zip": "\(zip),\(country)",
                "appid": OpenWeatherTarget.apiKey,
                "lang": Locale.current.identifier
            ]
        case .weatherOfCityName(let cityName):
            return URLEncoding() => [
                "q": cityName,
                "appid": OpenWeatherTarget.apiKey,
                "lang": Locale.current.identifier
            ]
        }
    }

    var baseURL: URL { "https://api.openweathermap.org/data/2.5".url! }

    var sampleData: Data { Data() }

    var headers: [String: String]? { nil }
}
