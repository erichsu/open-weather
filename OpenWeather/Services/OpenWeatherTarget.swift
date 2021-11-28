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

    // MARK: Internal

    static let apiKey = "95d190a434083879a6398aafd54d9e73"

    
    var route: Route {
        switch self {
        case .forecast: return .get("/forecast")
        }
    }

    var parameters: Parameters? {
        switch self {
        case .forecast(let id):
            return URLEncoding() => [
                "id": id,
                "appid": OpenWeatherTarget.apiKey
            ]
        }
    }

    var baseURL: URL { "https://api.openweathermap.org/data/2.5".url! }

    var sampleData: Data { Data() }

    var headers: [String: String]? { nil }
}
