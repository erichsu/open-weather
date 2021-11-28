//
//  OpenWeatherTargetTests.swift
//  OpenWeatherTests
//
//  Created by Eric Hsu on 2021/11/28.
//

import MoyaSugar
@testable import OpenWeather
import RxSwift
import XCTest

// MARK: - OpenWeatherTargetTests

class OpenWeatherTargetTests: XCTestCase {
    let sampleEndpointClosure = { (target: OpenWeatherTarget) -> Endpoint in
        Endpoint(url: URL(target: target).absoluteString,
                 sampleResponseClosure: { .networkResponse(200, target.sampleData) },
                 method: target.method,
                 task: target.task,
                 httpHeaderFields: target.headers)
    }

    lazy var stubbingProvider = MoyaProvider<OpenWeatherTarget>(
        endpointClosure: sampleEndpointClosure,
        stubClosure: MoyaProvider.immediatelyStub
    )
    let bag = DisposeBag()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let expect = expectation(description: "forecast response decoding should not fail")
        stubbingProvider.rx.request(.forecast(id: 123))
            .map([Forecast].self, atKeyPath: "list")
            .subscribe(
                onSuccess: { res in
                    XCTAssertFalse(res.isEmpty)
                    print(res)
                    expect.fulfill()
                },
                onFailure: { XCTFail("\($0)") }
            )
            .disposed(by: bag)
        waitForExpectations(timeout: 1, handler: nil)
    }
}

extension OpenWeatherTarget {
    var sampleData: Data {
        let bundle = Bundle(for: OpenWeatherTargetTests.self)
        switch self {
        case .forecast:
            let fileUrl = bundle.url(forResource: "ForecastResponse", withExtension: "json")
            return try! Data(contentsOf: fileUrl!)
        }
    }
}
