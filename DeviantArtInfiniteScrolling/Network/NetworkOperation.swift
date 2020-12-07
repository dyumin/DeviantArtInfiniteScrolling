//
//  NetworkOperation.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import Foundation
import Alamofire
import RxRelay

class NetworkOperation: AsynchronousOperation
{
    private let urlString: String
    private var request: Alamofire.DataRequest? = nil
    
//    public var response = ReplaySubject<AFDataResponse<Data>>.create(bufferSize: 1)
//    public var progress = ReplaySubject<Progress>.create(bufferSize: 1)
    public var response: BehaviorRelay<AFDataResponse<Data>?> = BehaviorRelay<AFDataResponse<Data>?>.init(value: nil)
    public var progress: BehaviorRelay<Progress?> = BehaviorRelay<Progress?>.init(value: nil)
    
    init(with url: String)
    {
        urlString = url
        super.init()
    }
    
    override func main()
    {
        let request = AlamofireManager.sharedSession.request(urlString)
        
        request.responseData(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        { [weak self] (response) in
            defer
            {
                if let self = self
                {
                    self.completeOperation()
                    self.request = nil
                }
            }
            
            self?.response.accept(response)
        }
//        request.downloadProgress(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.utility)) // todo: use serial queue
//        { [weak self] (progress) in
//            
//            self?.progress.accept(progress)
//        }
    }
    
    override func cancel()
    {
        request?.cancel()
        super.cancel()
    }
}
