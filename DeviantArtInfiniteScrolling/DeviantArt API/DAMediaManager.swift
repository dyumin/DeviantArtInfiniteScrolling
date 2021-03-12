//
//  DAMediaManager.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//  Этот ужас надо переписать, но для примера сойдет
//

import Foundation
import PINCache
import RxSwift
import RxRelay

class DeviationMedia
{
    private let disposeBag = DisposeBag()
    
    init(networkOperation: NetworkOperation)
    {
        self.networkOperation = networkOperation
        
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
    
    @Atomic private var _isInOperationQueue: Bool = false
    
    var isInOperationQueue: Bool
    {
        set
        {
            _isInOperationQueue = newValue
        }
        get
        {
            if (networkOperation.isFinished) // todo: track completion
            {
                return false
            }
            
            return _isInOperationQueue
        }
    }
    

    let image = ReplaySubject<UIImage?>.create(bufferSize: 1)
}

class DAMediaManager
{
    static let shared = DAMediaManager()
    private init() // please use shared
    {
        mediaOperationQueue.maxConcurrentOperationCount = 10 // AlamofireManager.sharedSession.sessionConfiguration.httpMaximumConnectionsPerHost
        cache = PINMemoryCache()
        cache.costLimit = 500 // keep last 500 elements
        cache.willRemoveObjectBlock =
        { (_, _, obj) in
            if let obj = obj as? DeviationMedia
            {
                obj.networkOperation.cancel()
            }
        }
        
        // I'm not so proud of this, but it will work for this example
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
                                
                                self.queueSize.accept(self.mediaDownwloadQueue.count)
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
    
    @Atomic var operationQueueIsIdle: Bool = true
    
    let cache: PINMemoryCache
    
    private let mediaDownwloadQueueLock = NSObject()
    var mediaDownwloadQueue = CircularBuffer<DeviationMedia>(capacity: 250) // load last 250 images
    
    let mediaOperationQueue = OperationQueue()
    
    func getContent(for deviation: Deviaton) -> DeviationMedia? // todo: refactor using global lock (?)
    {
        if (cache.totalCost < cache.costLimit)
        {
            print("totalCost: ", cache.totalCost)
        }
        
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
        else if let url = deviation.thumbs?.src ?? deviation.content?.src
        {
            let deviationMedia = DeviationMedia(networkOperation: NetworkOperation(with: url))
            cache.setObject(deviationMedia, forKey: uuidString, withCost: 1)
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
        
        // todo: report error
        return nil
    }
}
