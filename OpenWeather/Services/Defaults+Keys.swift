//
//  Defaults+Keys.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/29.
//

import CoreLocation
import Foundation
import RxSwift
import SwiftyUserDefaults

extension DefaultsKeys {
    var searchRecords: DefaultsKey<[String]> { .init("searchRecords", defaultValue: []) }
    var selectedLocations: DefaultsKey<[CLPlacemark]> { .init("selectedLocations", defaultValue: []) }
}

// MARK: - CLPlacemark + DefaultsSerializable

extension CLPlacemark: DefaultsSerializable {}

extension DefaultsAdapter {
    func observe<T: DefaultsSerializable>(_ key: DefaultsKey<T>,
                                          options: NSKeyValueObservingOptions = [.initial, .old, .new]) -> RxSwift.Observable<DefaultsObserver<T>.Update> where T == T.T
    {
        Observable.create { observer in
            let token = self.observe(key, options: options) { update in
                observer.onNext(update)
            }
            return Disposables.create { token.dispose() }
        }.delay(.microseconds(100), scheduler: MainScheduler.instance)
    }

    func observe<T: DefaultsSerializable>(_ keyPath: KeyPath<KeyStore, DefaultsKey<T>>,
                                          options: NSKeyValueObservingOptions = [.initial, .old, .new]) -> RxSwift.Observable<DefaultsObserver<T>.Update> where T == T.T
    {
        Observable.create { observer in
            let token = self.observe(keyPath, options: options) { update in
                observer.onNext(update)
            }
            return Disposables.create { token.dispose() }
        }.delay(.microseconds(100), scheduler: MainScheduler.instance)
    }
}
