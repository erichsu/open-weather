//
//  Forecast.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/28.
//

import BackedCodable
import Foundation

// MARK: - Forecast

struct Forecast: BackedDecodable {
    // MARK: Lifecycle

    init(_: DeferredDecoder) {}

    // MARK: Internal

    @Backed("dt", strategy: .secondsSince1970)
    var date: Date
}

#if DEBUG
extension Forecast {
    static let dummy = try! JSONDecoder().decode(Forecast.self, from: #"""
    {
        "dt": 1638111600,
        "main": {
            "temp": 275.71,
            "feels_like": 272.67,
            "temp_min": 274.4,
            "temp_max": 275.71,
            "pressure": 1006,
            "sea_level": 1006,
            "grnd_level": 989,
            "humidity": 86,
            "temp_kf": 1.31
        },
        "weather": [
            {
                "id": 804,
                "main": "Clouds",
                "description": "overcast clouds",
                "icon": "04n"
            }
        ],
        "clouds": {
            "all": 100
        },
        "wind": {
            "speed": 3.07,
            "deg": 212,
            "gust": 8.48
        },
        "visibility": 10000,
        "pop": 0,
        "sys": {
            "pod": "n"
        },
        "dt_txt": "2021-11-28 15:00:00"
    }
    """#.data(using: .utf8)!)
}

#endif
