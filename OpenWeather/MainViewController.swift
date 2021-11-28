//
//  ViewController.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/28.
//

import Contacts
import CoreLocation
import RxDataSources
import RxMoya
import RxRelay
import RxSwift
import SwiftyUserDefaults
import Then
import UIKit

// MARK: - MainViewController

final class MainViewController: UIViewController {
    // MARK: Internal

    typealias Section = SectionModel<String, Weather>

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSubviews()
        bindInput()
        bindOutput()
    }

    // MARK: Private

    private let bag = DisposeBag()
    private let state = State()
    private let event = Event()
    private lazy var searchController = SearchResultController()
    private lazy var dataSource = RxTableViewSectionedReloadDataSource<Section>(
        configureCell: { _, tableView, index, item in
            let cell = tableView.dequeueReusableCell(withClass: MainCell.self, for: index)
            cell.setup(with: item)
            return cell
        }
    )

    private lazy var settingBarItem = UIBarButtonItem(
        image: UIImage(systemName: "gear"),
        style: .plain,
        target: nil,
        action: nil
    )

    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.register(cellWithClass: MainCell.self)
    }

    private func setupSubviews() {
        title = "Weather"
        navigationItem.searchController = searchController
        navigationItem.rightBarButtonItem = settingBarItem

        view.addSubviews([tableView])
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindInput() {
        settingBarItem.rx.tap
            .bind(to: event.settingTapped)
            .disposed(by: bag)

        searchController.event.placeSelected
            .bind(to: event.selectedPlace)
            .disposed(by: bag)

        Defaults.observe(\.selectedLocations)
            .compactMap { $0.newValue }
            .flatMapLatest { places -> Observable<[Weather]> in
                let requests = places.map {
                    API.rx.request(.weatherOfCityName($0.name!))
                        .map(Weather.self)
                        .asObservable()
                }
                return Observable.combineLatest(requests)
            }
            .debug()
            .bind(to: state.weathers)
            .disposed(by: bag)
    }

    private func bindOutput() {
        Defaults.observe(\.searchMode)
            .bind(with: searchController) {
                switch $1.newValue {
                case .cityName?:
                    $0.searchBar.placeholder = "Search by City Name"
                default:
                    $0.searchBar.placeholder = "Search by Zip code"
                }
            }
            .disposed(by: bag)

//        event.selectedPlace
//            .debounce(.seconds(1), scheduler: MainScheduler.instance)
//            .flatMapLatest { _ in
//                API.rx.request(.forecast(id: 524901)).map { _ in }
//            }
//            .materialize()
//            .bind { res in
//                switch res {
//                case let .next(element):
//
//                    print("result get")
//                default: print("Error")
//                }
//            }
//            .disposed(by: bag)

        event.selectedPlace
            .do(onNext: {
                Defaults.selectedLocations = (Defaults.selectedLocations + [$0])
                    .withoutDuplicates(keyPath: \.name)
            })
            .flatMapLatest { place in
                API.rx.request(.weatherOfCityName(place.name!))
            }
            .materialize()
            .bind { res in
                switch res {
                case let .next(element):

                    print("result get")
                default: print("Error")
                }
            }
            .disposed(by: bag)


        state.weathers
            .map { [Section(model: "", items: $0)] }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
    }
}

extension MainViewController {
    struct Event {
        let settingTapped = PublishRelay<Void>()
        let selectedPlace = PublishRelay<CLPlacemark>()
    }

    struct State {
        let weathers = BehaviorRelay(value: [Weather]())
    }
}

// MARK: - MainCell

private final class MainCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let contentStack = UIStackView(
            arrangedSubviews: [titleLabel, weatherInfo, mainInfo],
            axis: .vertical,
            spacing: 8
        )

        contentView.addSubviews([contentStack])
        contentStack.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(16)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    func setup(with item: MainViewController.Section.Item) {
        titleLabel.text = item.name
        weatherInfo.text = item.weather
        mainInfo.text = "\(item.tempMin) ~ \(item.tempMax)"
    }

    // MARK: Private

    private lazy var titleLabel = UILabel()
    private lazy var weatherInfo = UILabel()
    private lazy var mainInfo = UILabel()
}
