//
//  SearchResultViewController.swift
//  Ninano
//
//  Created by 이가은 on 2022/07/15.
//

import UIKit

final class SearchResultViewController: UIViewController, UISearchBarDelegate{
    
    @IBOutlet weak var eventFilterButton: EventFilterButton!
    @IBOutlet private var performanceCollectionView: UICollectionView!
    @IBOutlet private weak var keywordNotification: UIButton!
    @IBOutlet private weak var keywordAddedNotification: UIStackView!
    @IBOutlet private weak var eventCollectionView: UICollectionView!
    private var searchBar = UISearchBar(frame: CGRect(x: 0, y: 0, width: 300, height: 0))
    private var keywordViewModel = KeywordDataModel()
    
    var eventList: [Event] = []
    var viewCatagory: SearchDetailCatagory?
    
    enum SearchDetailCatagory {
        case searchCatagory(navigationTitle: String)
        case searchResult
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate = self
        keywordAddedNotification.isHidden = true
        keywordNotification.isHidden = true
        // collectionView에 대한 설정
        performanceCollectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        performanceCollectionView.dataSource = self
        performanceCollectionView.delegate = self
        eventFilterButton.datedeliveryDelegate = self
        
        var backImage = UIImage(systemName: "chevron.backward.square.fill")
        backImage = backImage?.resizeImage(newWidth: 40)
        let undo = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(didTapBackButton))
        self.navigationItem.leftBarButtonItem = undo
        self.navigationController?.navigationBar.tintColor = UIColor(hex: "D15353")
        
        switch viewCatagory {
            case .searchCatagory(let navigationTitle):
                let searchCatagoryTitle = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 20))
                searchCatagoryTitle.textAlignment = .center
                searchCatagoryTitle.font = UIFont.systemFont(ofSize: 20)
                searchCatagoryTitle.text = navigationTitle
                self.navigationItem.titleView = searchCatagoryTitle
            case .searchResult:
                searchBar.placeholder = "Search User"
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: searchBar)
            case .none:
                print("viewCatagory error")
        }
        keywordAddedNotification.layer.cornerRadius = 15
        keywordNotification.layer.cornerRadius = 15
    }
    
    internal func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        dismissKeyboard(searchBar)
        
        let isKeywordInCoreData = keywordViewModel.keywordItems.contains { keywordList in
            return keywordList.keywordSubs == searchBar.text
        }
        if isKeywordInCoreData {
            keywordNotification.isHidden = true
        } else {
            keywordNotification.isHidden = false
        }
    }
    
    internal func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // TODO: filter CollectionView
    }
    
    private func dismissKeyboard(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    @objc private func didTapBackButton() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func keywordNotificationButton(_ sender: UIButton) {
        if let keyWord = searchBar.text {
            keywordViewModel.addKeywordItems(keyword: keyWord)
        }
        keywordAddedNotification.isHidden = false
        keywordNotification.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            UIView.animate(withDuration: 1) {
                self.keywordAddedNotification.isHidden = true
            }
        }
    }
}

extension SearchResultViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        guard let flow = collectionViewLayout as? UICollectionViewFlowLayout else { return CGSize() }
        let screen = UIScreen.main.bounds.width
        let inset = (25 / 390) * screen
        let spacing = (14 / 390) * screen
        
        let width = (screen - (inset * 2) - spacing) / 2
        let height = (4 / 3) * width + 65
        
        flow.minimumLineSpacing = spacing
        flow.sectionInset.left = inset
        
        return CGSize(width: width, height: height)
    }
    
}

// 컬렉션 뷰의 셀은 총 몇 개? (UICollectionViewDataSource)
// 컬렉션 뷰를 어떻게 보여줄 것인가 ? (UICollectionViewDelegate)
extension SearchResultViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    // UICollectionViewDataSource와 관련된 함수 2개
    /// 콜렉션 뷰에 총 몇 개의 셀(cell)을 표시할 것인지를 구현
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.eventList.count
    }
    /// 해당 cell에 무슨 view들을 표시할 지를 결정
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cellId = String(describing: PerformancesViewCell.self)
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? PerformancesViewCell {
            let eventData = self.eventList[indexPath.item]
            cell.updateEventCell(event: eventData)
            cell.contentView.layer.cornerRadius = 8
            return cell
        }
        
        return PerformancesViewCell()
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let eventDetailView = UIStoryboard(name: "EventDetail", bundle: .main).instantiateViewController(withIdentifier: "EventDetailViewController") as? EventDetailViewController else { return }
        self.navigationController?.pushViewController(eventDetailView, animated: true)
    }
}

protocol DateDelivable: AnyObject {
    func addDate(date: Date)
}

protocol FilterButtonClickable: AnyObject {
    func openLocalActionSheet(actionSheet: UIAlertController)
    func openCaledarSearchResultView()
}

extension SearchResultViewController: DateDelivable, FilterButtonClickable {
    
    func addDate(date: Date) {
        let koreanDate = date.convertDateToKoreanDate(.koreanDate)
        let button: UIButton = eventFilterButton.dateFilterButton
        button.setTitle(koreanDate, for: .normal)
        button.configuration?.baseBackgroundColor = UIColor(hex: "D5DCF8")
        button.configuration?.cornerStyle = .capsule
    }
    
    func openLocalActionSheet(actionSheet: UIAlertController) {
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func openCaledarSearchResultView() {
        guard let calenderModal = UIStoryboard(name: "CalenderModal", bundle: .main).instantiateViewController(withIdentifier: "CalenderModalViewController") as? CalenderModalViewController else { return }
        calenderModal.datedeliveryDelegate = self
        self.present(calenderModal, animated: true, completion: nil)
    }
}
