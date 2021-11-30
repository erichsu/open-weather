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

    typealias Section = SectionModel<String, Weather?>

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
            let place = Defaults.selectedLocations[index.row]
            cell.setup(with: item, place: place)
            return cell
        }
    )

    private lazy var placeholder = UILabel(text: "No data\nplease add weather via search bar ↑").then {
        $0.textAlignment = .center
        $0.numberOfLines = 0
    }

    private lazy var refreshControl = UIRefreshControl()
    private lazy var tableView = UITableView(frame: .zero, style: .insetGrouped).then {
        $0.register(cellWithClass: MainCell.self)
        $0.backgroundView = placeholder
        $0.refreshControl = refreshControl
    }

    private func setupSubviews() {
        title = "Weather"
        navigationItem.searchController = searchController
        searchController.searchBar.placeholder = "Search city name or zip code"

        view.addSubviews([tableView])
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindInput() {
        searchController.event.placeSelected
            .bind(to: event.selectedPlace)
            .disposed(by: bag)

        let refresh = refreshControl.rx
            .controlEvent(.valueChanged)
            .mapTo(Defaults.selectedLocations)

        let newLocations = Defaults.observe(\.selectedLocations)
            .compactMap { $0.newValue }

        Observable
            .merge(refresh, newLocations)
            .flatMapLatest { [weak self] places -> Observable<[Weather?]> in
                let requests = places.map {
                    API.rx.request(.weatherOfCityName($0.locality ?? $0.subLocality ?? $0.name!))
                        .map(Weather?.self)
                        .asObservable()
                        .catch {
                            print($0)
                            return .just(nil)
                        }
                }
                return Observable.combineLatest(requests)
                    .do(onSubscribed: { self?.refreshControl.beginRefreshing() })
                    .do(onDispose: { self?.refreshControl.endRefreshing() })
            }
            .bind(to: state.weathers)
            .disposed(by: bag)

        tableView.rx.itemDeleted
            .bind {
                Defaults.selectedLocations.remove(at: $0.row)
            }
            .disposed(by: bag)
    }

    private func bindOutput() {
        event.settingTapped
            .bind(with: self) { `self`, _ in self.showSettingAlert() }
            .disposed(by: bag)

        event.selectedPlace
            .bind {
                Defaults.selectedLocations = ([$0] + Defaults.selectedLocations)
                    .withoutDuplicates(keyPath: \.name)
            }
            .disposed(by: bag)

        state.weathers
            .map { [Section(model: "", items: $0)] }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)

        state.weathers
            .map(\.isEmpty).not()
            .bind(to: placeholder.rx.isHidden)
            .disposed(by: bag)
    }

    private func showSettingAlert() {
        let alert = UIAlertController()

        present(alert, animated: true)
    }
}

extension MainViewController {
    struct Event {
        let settingTapped = PublishRelay<Void>()
        let selectedPlace = PublishRelay<CLPlacemark>()
    }

    struct State {
        let weathers = BehaviorRelay(value: [Weather?]())
    }
}

// MARK: - MainCell

private final class MainCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = Theme.current.accentColor
        selectionStyle = .none
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

    func setup(with item: MainViewController.Section.Item, place: CLPlacemark?) {
        guard let item = item else {
            titleLabel.text = place?.name ?? "--"
            weatherInfo.text = "--"
            mainInfo.text = "--"
            return
        }
        titleLabel.text = item.name
        weatherInfo.text = item.weather
        mainInfo.text = "\(item.tempMin) ~ \(item.tempMax)℉"
    }

    // MARK: Private

    private lazy var titleLabel = UILabel().then {
        $0.textColor = Theme.current.textColor
    }

    private lazy var weatherInfo = UILabel()
    private lazy var mainInfo = UILabel()
}
