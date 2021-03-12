//
//  TableViewDataSource.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import UIKit
import RxRelay

class TableViewDataSource: NSObject, UITableViewDataSource, UITableViewDataSourcePrefetching
{
    var deviations: DeviatonsQueryResult = DeviatonsQueryResult(has_more: true, next_offset: 0, estimated_total: nil, results: [])
    let fetchingInProgress = BehaviorRelay<Bool>(value: false)
    var loadNextOnComplete = false

    // requires main thread
    func requestDeviations(into tableView: UITableView)
    {
        guard deviations.has_more, let next_offset = deviations.next_offset else {
            return
        }

        guard !fetchingInProgress.value else {
            loadNextOnComplete = true
            return
        }
        fetchingInProgress.accept(true)
        
        DispatchQueue.global(qos: .userInitiated).async {
            print("request next_offset: \(next_offset)")
            DAManager.shared.requestPopularDeviations(completion:
            { [self] (resp) in
                if let newDeviations = resp.value {
                    let currentDeviations = deviations.results.count // safe to read from background thread since fetchingInProgress is still true at this point

                    guard !newDeviations.results.isEmpty else {
                        DispatchQueue.main.async
                        {
                            fetchingInProgress.accept(false)
                            
                            if (loadNextOnComplete) {
                                loadNextOnComplete = false
                                requestDeviations(into: tableView)
                            }
                        }
                        // todo: report error
                        return
                    }

                    let newDeviationsCount = newDeviations.results.count // at least 1 entity is guaranteed

                    // build indexPaths
                    var indexPaths: [IndexPath] = []
                    indexPaths.reserveCapacity(newDeviationsCount)

                    for index in 0...newDeviationsCount - 1 {
                        indexPaths.append(IndexPath(row: currentDeviations + index, section: 0))
                    }

                    let tmpDeviations = deviations.withLatest(newDeviations) // safe to read from background thread since fetchingInProgress is still true at this point

                    DispatchQueue.main.async
                    {
                        fetchingInProgress.accept(false)
                        deviations = tmpDeviations
                        
                        if (loadNextOnComplete) {
                            loadNextOnComplete = false
                            requestDeviations(into: tableView)
                        }
                        
                        tableView.performBatchUpdates
                        {
                            tableView.insertRows(at: indexPaths, with: UITableView.RowAnimation.none)
                        }
                    }
                }
                else {
                    DispatchQueue.main.async
                    {
                        fetchingInProgress.accept(false)
                        
                        if (loadNextOnComplete) {
                            loadNextOnComplete = false
                            requestDeviations(into: tableView)
                        }
                    }
                    // todo: report error
                    return
                }
            }, next_offset)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        deviations.results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeviationPreviewCell.identifier, for: indexPath) as? DeviationPreviewCell else {
            assertionFailure()
            return UITableViewCell()
        }

        cell.data = deviations.results[indexPath.row]
        
        if (deviations.results.count - 1 == indexPath.row) {
            self.requestDeviations(into: tableView)
        }

        print("currently displaying: \(indexPath.row)")

        return cell
    }

    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath])
    {
        if let last = indexPaths.last {
            if (last.row + 100 >= (deviations.results.count - 1)) { // todo: magic numbers
                requestDeviations(into: tableView)
            }
        }
    }
}
