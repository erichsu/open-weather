//
//  SearchResultController.swift
//  OpenWeather
//
//  Created by Eric Hsu on 2021/11/28.
//

import Contacts
import RxCocoa
import RxDataSources
import RxSwift
import SwiftyUserDefaults
import UIKit

import CoreLocation

// MARK: - SearchResultController

final class SearchResultController: UISearchController {
    // MARK: Internal

    typealias Section = SectionModel<String, Item>

    let state = State()
    let event = Event()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        bindInput()
        bindOutput()
    }

    // MARK: Private

    private let bag = DisposeBag()
    private lazy var tableView = UITableView().then {
        $0.register(cellWithClass: SearchCell.self)
    }

    private lazy var dataSource = RxTableViewSectionedReloadDataSource<Section>(
        configureCell: { _, tableView, index, item in
            let cell = tableView.dequeueReusableCell(withClass: SearchCell.self, for: index)
            cell.setup(with: item)
            return cell
        },
        titleForHeaderInSection: { $0[$1].model }
    )

    private func setupSubviews() {
        view.addSubviews([tableView])
        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func bindInput() {
        searchBar.rx.text.orEmpty
            .bind(to: state.searchText)
            .disposed(by: bag)

        searchBar.rx.textDidEndEditing
            .withUnretained(searchBar) { searchBar, _ in searchBar.text }
            .filter { !$0.isNilOrEmpty }
            .unwrap()
            .bind {
                Defaults.searchRecords = (Defaults.searchRecords + [$0]).withoutDuplicates()
            }
            .disposed(by: bag)

        tableView.rx.modelDeleted(Section.Item.self)
            .bind {
                if case .history(let title) = $0 {
                    Defaults.searchRecords.removeAll(title)
                }
            }
            .disposed(by: bag)

        tableView.rx.modelSelected(Section.Item.self)
            .compactMap {
                guard case .place(let place, _) = $0 else { return nil }
                return place
            }
            .bind(to: event.placeSelected)
            .disposed(by: bag)

        tableView.rx.modelSelected(Section.Item.self)
            .compactMap {
                guard case .history(let text) = $0 else { return nil }
                return text
            }
            .bind(to: state.searchText)
            .disposed(by: bag)
    }

    private func bindOutput() {
        state.searchText
            .bind(to: searchBar.rx.text)
            .disposed(by: bag)

        state.searchText
            .debounce(.microseconds(500), scheduler: MainScheduler.instance)
            .filter { !$0.isEmpty }
            .withUnretained(self)
            .flatMapLatest { `self`, text -> Observable<[CLPlacemark]> in
                Observable
                    .combineLatest(self.placesOfName(text), self.placesOfZip(text))
                    .map { $0 + $1 }
            }
            .bind(to: state.locations)
            .disposed(by: bag)

        let currentLocation = Section(model: "", items: [.gps])
        let historySection = Defaults.observe(\.searchRecords)
            .compactMap { $0.newValue }
            .map { Section(model: "Recent Search", items: $0.map(Item.history)) }

        let suggestionSection = state.locations
            .withUnretained(self)
            .map { `self`, places in
                Section(model: "Locations", items: places.map { Item.place($0, self.state.searchText.value) })
            }

        Observable
            .combineLatest(historySection, suggestionSection)
            .map { [currentLocation, $0, $1] }
            .bind(to: tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)

        event.placeSelected
            .bind(with: self) { `self`, _ in self.dismiss(animated: true) }
            .disposed(by: bag)
    }

    private func placesOfZip(_ zip: String) -> Observable<[CLPlacemark]> {
        let geoCoder = CLGeocoder()

        let address = CNMutablePostalAddress()
        address.postalCode = zip
        address.isoCountryCode = "US"

        return Observable<[CLPlacemark]>.create { observer in
            geoCoder.geocodePostalAddress(address) { placeMarks, error in

                if let places = placeMarks {
                    if places.count > 0 {
                        observer.onNext(places)
                        observer.onCompleted()
                        return
                    }
                }
                if let error = error {
                    print("search zip error", error)
                    //                    observer.onError(error)
                    observer.onNext([])
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }

    private func placesOfName(_ name: String) -> Observable<[CLPlacemark]> {
        let geoCoder = CLGeocoder()

        let address = CNMutablePostalAddress()
        address.city = name
//        address.isoCountryCode = "US"

        return Observable<[CLPlacemark]>.create { observer in
            geoCoder.geocodePostalAddress(address) { placeMarks, error in

                if let places = placeMarks {
                    if places.count > 0 {
                        observer.onNext(places)
                        observer.onCompleted()
                        return
                    }
                }
                if let error = error {
                    print("search city name error", error)
                    //                    observer.onError(error)
                    observer.onNext([])
                    observer.onCompleted()
                }
            }
            return Disposables.create()
        }
    }
}

extension SearchResultController {
    enum Item {
        case gps
        case history(String)
        case place(CLPlacemark, String)
    }

    struct Event {
        let placeSelected = PublishRelay<CLPlacemark>()
    }

    struct State {
        let searchText = BehaviorRelay(value: "")
        let locations = BehaviorRelay(value: [CLPlacemark]())
    }
}

// MARK: - SearchCell

private final class SearchCell: UITableViewCell {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubviews([titleLabel])
        titleLabel.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 32, vertical: 0))
            $0.height.equalTo(44)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func prepareForReuse() {
        super.prepareForReuse()
        accessoryView = nil
        titleLabel.text = nil
        titleLabel.font = .systemFont(ofSize: 17)
    }

    func setup(with item: SearchResultController.Section.Item) {
        switch item {
        case .gps:
            titleLabel.text = "Current Location"
            accessoryView = UIImageView(image: UIImage(systemName: "location"))
        case .history(let title):
            titleLabel.text = title
        case .place(let place, let search):
            let text = [place.postalCode, place.locality ?? place.subLocality ?? place.name, place.isoCountryCode]
                .compactMap { $0 }
                .joined(separator: ", ")
            titleLabel.attributedText = NSAttributedString(string: text)
                .applying(attributes: [.font: UIFont.boldSystemFont(ofSize: 17)], toOccurrencesOf: search)
        }
    }

    // MARK: Private

    private lazy var titleLabel = UILabel()
}
