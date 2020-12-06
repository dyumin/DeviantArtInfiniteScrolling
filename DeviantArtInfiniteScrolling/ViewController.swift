//
//  ViewController.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import UIKit
import RxSwift

class ViewController: UIViewController, UITableViewDelegate
{
    private var disposeBag = DisposeBag()
    
    @IBOutlet weak var pagingDoneLabel: UILabel!
    {
        didSet
        {
            
        }
    }
    
    
    @IBOutlet weak var pagingActivityIndicator: UIActivityIndicatorView!
    {
        didSet
        {
            
        }
    }
    
    
    @IBOutlet weak var tableView: UITableView!
    {
        didSet
        {
            if let tableView = tableView
            {
                tableView.register(UINib(nibName: DeviationPreviewCell.identifier, bundle: nil), forCellReuseIdentifier: DeviationPreviewCell.identifier)
            }
        }
    }
    
    private let datasource: TableViewDataSource = TableViewDataSource()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        DAManager.shared.sessionTokenStatus.observeOn(MainScheduler.instance).subscribe
        { [weak self] (status) in
            if (status.element == .Success)
            {
                guard let self = self else {
                    return
                }
                
                self.tableView.dataSource = self.datasource
                self.tableView.prefetchDataSource = self.datasource
                self.datasource.requestDeviations(into: self.tableView)
            }
        }.disposed(by: disposeBag)
    }
}

