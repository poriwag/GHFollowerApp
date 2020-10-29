//
//  FollowerListVC.swift
//  GHFollowers
//
//  Created by Sean Allen on 12/30/19.
//  Copyright © 2019 Sean Allen. All rights reserved.
//

import UIKit

protocol FollowerListVCDelegate: class {
    func didrequestFollowers(for username: String)
    
}

class FollowerListVC: UIViewController {
    
    
    //enum is hashable by default
    enum Section {
        case main
    }
    var username: String!
    var followers: [Follower] = []
    var filteredFollowers: [Follower] = []
    var page: Int = 1
    var hasMoreFollowers = true
    var isSearching = false

    init(username: String){
        super.init(nibName: nil, bundle: nil)
        self.username = username
        title = username
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<Section, Follower>!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        configureViewController()
        getFollowers(username: username, page: page)
        configureDataSource()
        configureSearchController()
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    func configureCollectionView() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UIHelper.createThreeColumnFlowLayout(in: view ))
        view.addSubview(collectionView)
        collectionView.delegate = self
        collectionView.backgroundColor = .systemBackground
        collectionView.register(FollowerCell.self, forCellWithReuseIdentifier: FollowerCell.reuseID)
    }
    
    func configureViewController(){
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonTapped))
        navigationItem.rightBarButtonItem = addButton
    }
    
    func configureSearchController() {
        let searchController = UISearchController()
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Search for a username"
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        
        
    }

    
    func getFollowers(username: String, page: Int) {
        
        //this function from the our UIViewController Extension calls a container view that shows load icon
        //It will always execute this line of code first, then it will do a network call
        showLoadingView()
        NetworkManager.shared.getFollowers(for: username, page: page) {[weak self] result in
            
            //this is so we dont haeve to make all the selfs optional (it force unwracps the self
            guard let self = self else { return }
            //once the network call is made, it will remove the network call, and it will call function to dimsiss load
            self.dismissLoadingView()
            
            switch result {
                
                case .success(let followers):
                    // making checks to not create extra paginations
                    if followers.count < 100 {
                        self.hasMoreFollowers = false
                    }
                    self.followers.append(contentsOf: followers)
                    if self.followers.isEmpty {
                        let message = "This user doesnt have any followers. go Follow them 😀"
                        DispatchQueue.main.async {
                            self.showEmptyStateView(with: message, in: self.view)
                            return
                        }
                        
                    }
                    //to make sure I have my data and update followers
                    self.updateData(on: self.followers)
                    
                case .failure(let error):
                    self.presentGFAlertOnMainThread(title: "Bad Stuff Happened", message: error.rawValue, buttonTitle: "Ok")
            }
        }
        
    }
    
    func configureDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, Follower>(collectionView: collectionView, cellProvider: {(collectionView, indexPath, follower) -> UICollectionViewCell? in
            
            //index path determined in datasource. Regular default cell( Not follower cell
            //so we need to .... as! Follower Cell casts a FollowerCell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FollowerCell.reuseID, for: indexPath) as! FollowerCell
            //now that its setup, its time to configure our cell with set(follower: )
            //for every follower, it sends it to Follower cell, then sets cell and config
            cell.set(follower: follower)
            
            return cell
            
        })
    }
    
    func updateData(on followers: [Follower]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, Follower>()
        //this line of code takes an array of Section, but we only have 1 case .main
        snapshot.appendSections([.main])
        //now we need to add array of followers
        snapshot.appendItems(followers)
        
        //dispatch queueu is to use on background thead to make it very safe
        DispatchQueue.main.async {
            // magic function for animation
            self.dataSource.apply(snapshot, animatingDifferences: true)
        }
        
    }
    
    @objc func addButtonTapped() {
        showLoadingView()
        
        NetworkManager.shared.getUserInfo(for: username) {[ weak self] result in
            guard let self = self else { return }
            self.dismissLoadingView()
            
            switch result {
            case .success(let user):
                
                let favorite = Follower(login: user.login, avatarUrl: user.avatarUrl)
                
                PersistenceManager.updateWith(favorite: favorite, actionType: .add) {[weak self] error in
                    guard let self = self else {return}
                    
                    guard let error = error else {
                        self.presentGFAlertOnMainThread(title: "Success!", message: "You have successfully added this user", buttonTitle: "Hooray!")
                        return
                    }
                    
                    self.presentGFAlertOnMainThread(title: "Soemthing went Wrong", message: error.rawValue, buttonTitle: "OK")
                    
                    
                }
                
            case .failure(let error):
                self.presentGFAlertOnMainThread(title: "Something went wrong", message: error.rawValue, buttonTitle: "OK")
            }
        }
    }
}

extension FollowerListVC: UICollectionViewDelegate {
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate declerate: Bool) {
        //doing math to determine to total length of the scroll view
        
        let offsetY         = scrollView.contentOffset.y
        let contentHeight   = scrollView.contentSize.height
        let height          = scrollView.frame.size.height
        
        if offsetY > contentHeight - height {
            //increments page if the offsetY is bigger then the content height, which moeans theres more users so we increment page
            // guard statement says if its false it will exit
            guard hasMoreFollowers else { return }
            page += 1
            getFollowers(username: username, page: page)
        }
    }
    
    //this collection view will present the UserInfoVC (the user selected) with the correct selected user
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        //terenary if statement, if true filtered followers, else non filtered
        let activeArray = isSearching ? filteredFollowers : followers
        //plugging in specific item from array on where they tapped
        let follower = activeArray[indexPath.item]
        
        let destVC              = UserInfoVC()
        destVC.username         = follower.login
        destVC.delegate         = self
        let navController       = UINavigationController(rootViewController: destVC)
        present(navController, animated: true)
        
        
    }
}

extension FollowerListVC: UISearchResultsUpdating, UISearchBarDelegate{
    func updateSearchResults(for searchController: UISearchController) {
        
        //First we are making sure with the optional that it is Not empty. We check if its not empty, and update whats on searchbar
        guard let filter = searchController.searchBar.text, !filter.isEmpty else {
            return
        }
        isSearching = true
        //going tohrough our follower array, and we are going through our search filter
        //$0 will check login, lowercase it to even everything, now filter followers will have only things in filter (all lowercase)
        filteredFollowers = followers.filter { $0.login.lowercased().contains(filter.lowercased())}
        updateData(on: filteredFollowers)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        updateData(on: followers)
        isSearching = false
    }
}

extension FollowerListVC: FollowerListVCDelegate {
    func didrequestFollowers(for username: String) {
        
        //resetting the whole page
        self.username = username
        title = username
        page = 1
        followers.removeAll()
        filteredFollowers.removeAll()
        collectionView.setContentOffset(.zero, animated: true)
        getFollowers(username: username, page: page)
        
    }
    
    
}
    
    

