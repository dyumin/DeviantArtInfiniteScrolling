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
    @IBOutlet weak var pagingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var mediaTasksQueueSizeLabel: UILabel!
    @IBOutlet weak var mediaTasksLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    {
        didSet
        {
            if let tableView = tableView {
                tableView.register(UINib(nibName: DeviationPreviewCell.identifier, bundle: nil), forCellReuseIdentifier: DeviationPreviewCell.identifier)
            }
        }
    }

    private let datasource: TableViewDataSource = TableViewDataSource()

    var kvoToken: NSKeyValueObservation?

    override func viewDidLoad()
    {
        super.viewDidLoad()

        DAManager.shared.sessionTokenStatus.observeOn(MainScheduler.instance).subscribe
        { [weak self] (status) in
            if (status.element == .Success) {
                guard let self = self else {
                    return
                }

                self.tableView.dataSource = self.datasource
                self.tableView.prefetchDataSource = self.datasource
                self.datasource.requestDeviations(into: self.tableView)
            }
            else {
                print("\(#file): \(#function) line \(#line): error: \(status)")
            }
        }.disposed(by: disposeBag)

        DAMediaManager.shared.queueSize.observeOn(MainScheduler.instance).subscribe
        { [weak self] (queueSize) in
            if let size = queueSize.element {
                self?.mediaTasksQueueSizeLabel.text = String(size)
            }
        }.disposed(by: disposeBag)

        self.datasource.fetchingInProgress.observeOn(MainScheduler.instance).subscribe
        { [weak self] (fetchingInProgress) in
            if let inProgress = fetchingInProgress.element, let self = self {
                if (inProgress) {
                    self.pagingDoneLabel.isHidden = true
                    self.pagingActivityIndicator.isHidden = false
                    self.pagingActivityIndicator.startAnimating()
                }
                else {
                    self.pagingDoneLabel.isHidden = false
                    self.pagingActivityIndicator.isHidden = true
                    self.pagingActivityIndicator.stopAnimating()
                }
            }
        }.disposed(by: disposeBag)

        kvoToken = DAMediaManager.shared.mediaOperationQueue.observe(\.operationCount, options: .new)
        { [weak self] (_, change) in
            if let new = change.newValue {
                DispatchQueue.main.async
                {
                    self?.mediaTasksLabel.text = String(new)
                }
            }
        }
    }
}

