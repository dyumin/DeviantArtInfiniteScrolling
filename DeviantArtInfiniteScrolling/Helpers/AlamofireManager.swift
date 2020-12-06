//
//  AlamofireManager.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import Alamofire

class AlamofireManager
{
    private init() {} // use sharedSession
    
    static let sharedSession: Alamofire.Session =
    {
        let configuration = URLSessionConfiguration.default
        
        // Timeout in 120s
        configuration.timeoutIntervalForRequest = 120
        
        return Alamofire.Session(configuration: configuration)
    }()
}

extension DataRequest
{
    @discardableResult
    public func responseJSON(queue: DispatchQueue = .main,
                             completionHandler: @escaping (AFDataResponse<Any>) -> Void) -> Self {
        response(queue: queue,
                 responseSerializer: JSONResponseSerializer(dataPreprocessor: JSONResponseSerializer.defaultDataPreprocessor,
                                                            emptyResponseCodes: JSONResponseSerializer.defaultEmptyResponseCodes,
                                                            emptyRequestMethods: JSONResponseSerializer.defaultEmptyRequestMethods,
                                                            options: .allowFragments),
                 completionHandler: completionHandler)
    }
}
