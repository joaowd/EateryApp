//
//  RestaurantViewController.swift
//  Eatery
//
//  Created by João Palma on 17/11/2020.
//

import UIKit

final class RestaurantsViewController: BaseViewController<RestaurantsViewModel>, UISearchBarDelegate {
    private var _collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    
    private lazy var _collectionDataSourceProvider = RestaurantsCollectionDataSource(
        collectionView: _collectionView,
        fetchHandler: _fetchMoreRestaurantsHandler,
        favoriteHandler: _setRestaurantAsfavoriteHandler
    )
    
    private lazy var _activityIndicatorView = UIWidgets.setActivityIndicatoryInto(view: self.view)
    private let _backgroundImage = UIImageView(image: UIImage(systemName: "leaf")?.withTintColor(UIColor.Theme.lightGrey, renderingMode: .alwaysOriginal))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Restaurants"
        _setupView()
    }
    
    private func _setupView() {
        _setData()
        _configureFilterButton()
        _configureSearchController()
        _configureCollectionView()
        _configureActivityIndicator()
        _configureViewBackgroundImage()
    }
    
    private func _setData() {
        viewModel.restaurantList.data.addObserver(observer: "restaurants") { [weak self] in
            guard let self = self else { return }
            guard !self.viewModel.isSearching else { return }
            
            print(self.viewModel.restaurantList.data.value.count)
            
            DispatchQueue.main.async {
                self._backgroundImage.isHidden = !self.viewModel.restaurantList.data.value.isEmpty
                self._collectionDataSourceProvider.updateData(on: self.viewModel.restaurantList.data.value, isSearching: false)
            }
        }
        
        viewModel.searchRestaurantList.data.addObserver(observer: "searchRestaurants") { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self._collectionDataSourceProvider.updateData(on: self.viewModel.searchRestaurantList.data.value, isSearching: true)
            }
        }
    }
    
    private func _configureFilterButton() {
        let filterButton = UIBarButtonItem(image: UIImage(systemName: "line.horizontal.3.decrease.circle"), style: .done, target: self, action: #selector(_filterAction))
        self.navigationItem.rightBarButtonItem = filterButton
    }
    
    @objc private func _filterAction() {}
    
    private func _configureSearchController() {
        let searchController = UISearchController()
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.searchTextField.backgroundColor = UIColor.Theme.black.withAlphaComponent(0.35)

        searchController.searchBar.setImage(UIImage(systemName: "magnifyingglass")?.withTintColor(UIColor.lightGray, renderingMode: .alwaysOriginal),
                                            for: UISearchBar.Icon.search, state: .normal)

        searchController.searchBar.setImage(UIImage(systemName: "xmark.circle.fill")?.withTintColor(UIColor.Theme.white, renderingMode: .alwaysOriginal),
                                            for: UISearchBar.Icon.clear, state: .normal)

        searchController.searchBar.searchTextField.attributedText =
            NSAttributedString.init(string: "", attributes: [NSAttributedString.Key.foregroundColor: UIColor.Theme.white])

        searchController.searchBar.searchTextField.attributedPlaceholder =
            NSAttributedString.init(string: "Search", attributes: [NSAttributedString.Key.foregroundColor: UIColor.lightGray])

        self.navigationItem.searchController = searchController
    }
    
    private func _configureCollectionView() {
        _setCollectionViewHorizontalScroll()
        
        self.view.addSubview(_collectionView)
        
        _collectionView.contentInset = UIEdgeInsets(top: 12, left: 12, bottom: 10, right: 12)
        _collectionView.delegate = _collectionDataSourceProvider
        _collectionView.dataSource = _collectionDataSourceProvider
        _collectionView.backgroundColor = .clear
        _collectionView.showsHorizontalScrollIndicator = false
        
        _collectionView.anchor(top: self.view.topAnchor, leading: self.view.safeAreaLayoutGuide.leadingAnchor,
                               bottom: self.view.bottomAnchor, trailing: self.view.safeAreaLayoutGuide.trailingAnchor)
    }
    
    private func _setCollectionViewHorizontalScroll() {
        if let flowLayout = _collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flowLayout.scrollDirection = .vertical
        }
    }
    
    private func _configureActivityIndicator() {
        viewModel.isBusy.addAndNotify(observer: "isBusy") { [weak self] in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self._activityIndicatorView.isHidden = !self.viewModel.isBusy.value
            }
        }
    }
    
    private func _configureViewBackgroundImage() {
        self.view.addSubview(_backgroundImage)
        
        _backgroundImage.centerInSuperview(size: CGSize(width: 60, height: 55))
    }
    
    private func _fetchMoreRestaurantsHandler() {
        viewModel.fetchMoreRestaurantsCommand.executeIf()
    }
    
    private func _setRestaurantAsfavoriteHandler(restaurantId: String) {
        viewModel.favoriteRestaurantCommand.execute(restaurantId)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        viewModel.seachRestaurantCommand.execute(searchText)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        viewModel.cancelSearchRestaurantCommand.execute()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate { _ in self._collectionView.collectionViewLayout.invalidateLayout() }
    }
}
