//
//  DAMediaManager.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import Foundation
import PINCache
import RxSwift
import RxRelay

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
        mediaOperationQueue.maxConcurrentOperationCount = 1 // todo: there is some problems with 1
        cache = PINMemoryCache()
        cache.costLimit = 50 // keep last 100 elements
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
        
        kvoToken = mediaOperationQueue.observe(\.operationCount, options: [.old, .new])
        { [weak self] (OperationQueue, change) in
            
            if let oldValue = change.oldValue, let newValue = change.newValue
            {
                if (newValue > oldValue) // task was added
                {
                    if let self = self
                    {
                        self.operationQueueIsIdle = false
                    }

                    return
                }
                if (newValue == 0)
                {
                    self?.operationQueueIsIdle = true
                }
                
                DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async // todo: optimise
                {
                    if let self = self
                    {
                        let maxConcurrentOperationCount = self.mediaOperationQueue.maxConcurrentOperationCount
                        
                        if (newValue < maxConcurrentOperationCount)
                        {
                            var diff = maxConcurrentOperationCount - newValue // how many tasks to add
                            
                            UniqueLock(self.mediaDownwloadQueueLock)
                            {
                                while diff > 0 && self.mediaDownwloadQueue.count != 0
                                {
                                    let task = self.mediaDownwloadQueue.popBack()
                                    if (!task.ready && !task.isInOperationQueue)
                                    {
                                        self.mediaOperationQueue.addOperation(task.networkOperation)
                                        task.isInOperationQueue = true
                                        diff -= 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
            
            if let self = self
            {
                UniqueLock(self.mediaDownwloadQueueLock)
                {
                    self.queueSize.accept(self.mediaDownwloadQueue.count)
                }
            }
        }
    }
    var kvoToken: NSKeyValueObservation?
    
    
    let queueSize = BehaviorRelay<Int>(value: 0)
    
    private let operationQueueIsIdleLock = NSObject()
    private var _operationQueueIsIdle: Bool = true
    var operationQueueIsIdle: Bool
    {
        set
        {
            UniqueLock(operationQueueIsIdleLock) { _operationQueueIsIdle = newValue }
        }
        get
        {
            var operationQueueIsIdleTmp = false
            UniqueLock(operationQueueIsIdleLock) { operationQueueIsIdleTmp = _operationQueueIsIdle }
            return operationQueueIsIdleTmp
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
        
        let uuidString = deviation.deviationid.uuidString
        if let deviationMedia = cache.object(forKey: uuidString) as? DeviationMedia
        {
            print("requesting: \(deviation.title ?? "") by \(deviation.author_username ?? "") (1)")
            UniqueLock(mediaDownwloadQueueLock)
            {
                if (!deviationMedia.ready && !deviationMedia.isInOperationQueue)
                {
                    if (!operationQueueIsIdle)
                    {
                        mediaDownwloadQueue.pushBack(deviationMedia) // todo: check if it is already there
                    }
                    else
                    {
                        self.mediaOperationQueue.addOperation(deviationMedia.networkOperation)
                        deviationMedia.isInOperationQueue = true
                    }
                }
            }

            
            return deviationMedia
        }
        else if let url = deviation.content?.src
        {
            let deviationMedia = DeviationMedia(networkOperation: NetworkOperation(with: url))
            cache.setObject(deviationMedia, forKey: uuidString, withCost: 1)
            // setObject(deviationMedia, forKey: uuidString)
            print("requesting: \(deviation.title ?? "") by \(deviation.author_username ?? "") (2)")
            UniqueLock(mediaDownwloadQueueLock)
            {
                if (!operationQueueIsIdle)
                {
                    mediaDownwloadQueue.pushBack(deviationMedia)
                }
                else
                {
                    self.mediaOperationQueue.addOperation(deviationMedia.networkOperation)
                    deviationMedia.isInOperationQueue = true
                }
            }
            
            return deviationMedia
        }
        
        
        
        return nil
    }
}
