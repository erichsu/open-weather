//
//  Weather.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/29.
//

import BackedCodable
import Foundation

// MARK: - Weather

struct Weather: BackedDecodable {
    init(_: DeferredDecoder) {}

    @Backed()
    var name: String

    @Backed(Path("weather", 0, "main"))
    var weather: String

    @Backed(Path("main", "temp_min"))
    var tempMin: Double

    @Backed(Path("main", "temp_max"))
    var tempMax: Double
}

#if DEBUG
extension Weather {
    static let dummy = try! JSONDecoder().decode(Weather.self, from: #"""
    {
        "coord": {
            "lon": 120.2133,
            "lat": 22.9908
        },
        "weather": [
            {
                "id": 701,
                "main": "Mist",
                "description": "mist",
                "icon": "50n"
            }
        ],
        "base": "stations",
        "main": {
            "temp": 294.1,
            "feels_like": 294.71,
            "temp_min": 294.1,
            "temp_max": 295.03,
            "pressure": 1015,
            "humidity": 94
        },
        "visibility": 4000,
        "wind": {
            "speed": 1.03,
            "deg": 350
        },
        "clouds": {
            "all": 75
        },
        "dt": 1638123408,
        "sys": {
            "type": 1,
            "id": 7945,
            "country": "TW",
            "sunrise": 1638138122,
            "sunset": 1638177186
        },
        "timezone": 28800,
        "id": 1668355,
        "name": "Tainan City",
        "cod": 200
    }
    """#.data(using: .utf8)!)
}
#endif
