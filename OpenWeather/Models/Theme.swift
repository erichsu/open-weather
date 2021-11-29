//
//  Theme.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/30.
//

import UIKit

enum Theme {
    case primary
    case secondary
    case other

    static var current: Theme {
        switch Locale.current.identifier {
        case "en_CA": return .secondary
        case "en_AU": return .other
        default: return .primary
        }
    }

    // MARK: Internal

    var accentColor: UIColor {
        switch self {
        case .primary: return .white
        case .secondary: return .systemPink
        case .other: return .systemTeal
        }
    }

    var textColor: UIColor {
        switch self {
        case .primary: return .black
        case .secondary: return .white
        case .other: return .darkGray
        }
    }
}
