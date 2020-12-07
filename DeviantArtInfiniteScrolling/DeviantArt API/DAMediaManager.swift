//
//  DAMediaManager.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import Foundation
import PINCache
import RxSwift

class DeviationMedia
{
    private let stateLock = NSObject()
    
    private let disposeBag = DisposeBag()
    
    init(networkOperation: NetworkOperation)
    {
        self.networkOperation = networkOperation
        
        
//        self.networkOperation.response.asObservable().bind(to: <#T##AFDataResponse<Data>?...##AFDataResponse<Data>?#>)
        
        self.networkOperation.response.asObservable().skip(1).map // todo: fix this skip(1) // todo: use bind
        { (response) -> UIImage? in
            if let data = response?.data
            {
                let image = UIImage(data: data)
                return image
            }
            return nil
        }.subscribe
        { [weak self] (event) in
            
            if let image = event.element
            {
                self?.image.on(.next(image))
            }
        }.disposed(by: disposeBag)
    }

    let networkOperation: NetworkOperation
    
    var ready: Bool
    {
        get
        {
            networkOperation.isFinished
        }
    }
    
    private var _isInOperationQueue: Bool = false
    var isInOperationQueue: Bool
    {
        set
        {
            UniqueLock(stateLock) { _isInOperationQueue = newValue }
        }
        get
        {
            if (networkOperation.isFinished) // todo: ???
            {
                return false
            }
            
            var isInOperationQueueTmp = false
            UniqueLock(stateLock) { isInOperationQueueTmp = _isInOperationQueue }
            return isInOperationQueueTmp
        }
    }
    
    deinit
    {
        
    }
    
    
    
    let image = ReplaySubject<UIImage?>.create(bufferSize: 1)
    
//    var image: UIImage?
//    {
//        get
//        {
//            if let data = networkOperation.response.value?.data
//            {
//                let image = UIImage(data: data)
//                return image
//            }
//            return nil
//        }
//    }
}

//func ff(_ block:PINCacheObjectBlock)
//{
//    block.(<#T##PINCaching#>, <#T##String#>, <#T##Any?#>)
//}


class DAMediaManager
{
    static let shared = DAMediaManager()
    private init() // please use shared
    {
        mediaOperationQueue.maxConcurrentOperationCount = 1
        cache = PINMemoryCache()
        cache.costLimit = 100 // keep last 100 elements
        cache.willRemoveObjectBlock =
        { (_, _, obj) in
            if let obj = obj as? DeviationMedia
            {
                if (!obj.networkOperation.isExecuting)
                {
                    obj.networkOperation.cancel()
                }
            }
        }
    }
    
    let cache: PINMemoryCache
    
    private let mediaDownwloadQueueLock = NSObject()
    var mediaDownwloadQueue = CircularBuffer<DeviationMedia>(capacity: 50) // load last 50 images
    
//    private let responseQuenue = DispatchQueue.global(qos: .default)
    
//    private let mediaOperationQueueLock = NSObject()
    let mediaOperationQueue = OperationQueue()
    
    
    func getContent(for deviation: Deviaton) -> DeviationMedia? // todo: use global lock?
    {
        print("totalCost: ", cache.totalCost)
        
        defer
        {
            UniqueLock(mediaDownwloadQueueLock)
            {
                for task in mediaDownwloadQueue
                {
                    mediaOperationQueue.addOperation(task.networkOperation)
                    task.isInOperationQueue = true
                }
                mediaDownwloadQueue.removeAll()
            }
        }
        
        let uuidString = deviation.deviationid.uuidString
        if let deviationMedia = cache.object(forKey: uuidString) as? DeviationMedia
        {
            if (!deviationMedia.ready && !deviationMedia.isInOperationQueue)
            {
                UniqueLock(mediaDownwloadQueueLock)
                {
                    mediaDownwloadQueue.append(deviationMedia)
                }
            }
            return deviationMedia
        }
        else if let url = deviation.content?.src
        {
            let deviationMedia = DeviationMedia(networkOperation: NetworkOperation(with: url))
            cache.setObject(deviationMedia, forKey: uuidString, withCost: 1)
            // setObject(deviationMedia, forKey: uuidString)
            
            UniqueLock(mediaDownwloadQueueLock)
            {
                mediaDownwloadQueue.append(deviationMedia)
            }
            return deviationMedia
        }
        
        
        
        return nil
    }
}
