//
//  TableViewDataSource.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import UIKit

class TableViewDataSource: NSObject, UITableViewDataSource, UITableViewDataSourcePrefetching
{
    let fetchNextInProgressLock: NSObject = NSObject()
    var fetchNextInProgress: Bool = false
    
    let deviationsLock: NSObject = NSObject()
    var deviations: DeviatonsQueryResult = DeviatonsQueryResult(has_more: true, next_offset: 0, estimated_total: nil, results: [])
    
    func requestDeviations(into tableView: UITableView)
    {
        let fetchNextInProgressScopedLock = UniqueLock(fetchNextInProgressLock)
        if (fetchNextInProgress)
        {
            return
        }
        fetchNextInProgress = true
        fetchNextInProgressScopedLock.unlock()
        
        let deviationsScopedLock = UniqueLock(deviationsLock)
        guard deviations.has_more, let next_offset = deviations.next_offset else
        {
            return
        }
        deviationsScopedLock.unlock()
        
        print("request next: \(next_offset)")
        DAManager.shared.requestPopularDeviations(completion:
        { [self] (resp) in
            
            if let newDeviations = resp.value
            {
                let currentDeviations = deviations.results.count
                
                guard !newDeviations.results.isEmpty else
                {
                    // todo: report error
                    return
                }
                
                let newDeviationsCount = newDeviations.results.count
                
                // build indexPaths
                var indexPaths: [IndexPath] = []
                indexPaths.reserveCapacity(newDeviationsCount)
            
                for index in 0...newDeviationsCount - 1
                {
                    indexPaths.append(IndexPath(row: currentDeviations + index, section: 0))
                }
                
                let tmpDeviations = deviations.withLatest(newDeviations)
       
                UniqueLock(deviationsLock)
                {
                    deviations = tmpDeviations
                }
                
                UniqueLock(fetchNextInProgressLock)
                {
                    fetchNextInProgress = false
                }

                DispatchQueue.main.async
                {
                    tableView.performBatchUpdates
                    {
                        tableView.insertRows(at: indexPaths, with: UITableView.RowAnimation.fade)
                    } completion:
                    { (animationsFinished) in

                    }
                }
            }
            else
            {
                // todo: report error
                return
            }
        }, next_offset)
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        let lock = UniqueLock(deviationsLock)
        return deviations.results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: DeviationPreviewCell.identifier, for: indexPath) as? DeviationPreviewCell
        else
        {
            assertionFailure()
            return UITableViewCell()
        }
        
        UniqueLock(deviationsLock)
        {
            cell.data = deviations.results[indexPath.row]
        }
        
        print("currently displaying: \(indexPath.row)")

        return cell
    }
    
    func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath])
    {
        if let last = indexPaths.last
        {
            let lock = UniqueLock(deviationsLock)
            if (last.row + 9999 >= (deviations.results.count - 1)) // todo magic numbers
            {
                lock.unlock()
                requestDeviations(into: tableView)
            }
        }
        
//        print(indexPaths)
    }
}
