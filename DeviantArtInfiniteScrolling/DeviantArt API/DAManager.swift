//
//  DAManager.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import UIKit
import RxSwift
import Alamofire

fileprivate class Endpoints
{
    static let accessTokenURL = "https://www.deviantart.com/oauth2/token"
    
    static let popular = "https://www.deviantart.com/api/v1/oauth2/browse/popular"
}

fileprivate let client_id = "14054"
fileprivate let client_secret = "f5100ec651f44e2ddc0a60e216a315d4"

enum Status
{
    case Unknown
    case Error
    case Success
}

public enum DAError: Error {
    case ResponseCastFailedFor(_ obj: Any)
    case CustomSerializationFailed
    case ResponseReportedError(code: Int?, _ response: Dictionary<String, Any>)
}

// qi == query item
let qiclient_id = "client_id"
let qiclient_secret = "client_secret"
let qigrant_type = "grant_type"
let qioffset = "offset"
let qilimit = "limit"
let qiaccess_token = "access_token"
let qitimerange = "timerange"

struct Content
{
    let src: String
    let height: UInt
    let width: UInt
    let transparency: Bool
    let filesize: UInt64
    
    init?(_ json:Dictionary<String,Any>)
    {
        guard let src = json[Content.cisrc] as? String
              ,let height = json[Content.ciheight] as? UInt
              ,let width = json[Content.ciwidth] as? UInt
              ,let transparency = json[Content.citransparency] as? Bool
              ,let filesize = json[Content.cifilesize] as? UInt64
        else
        {
            assertionFailure("\(#function): failed to create instance with \(json)")
            return nil
        }
        
        self.src = src
        self.height = height
        self.width = width
        self.transparency = transparency
        self.filesize = filesize
    }
    
    static let cisrc = "src"
    static let ciheight = "height"
    static let ciwidth = "width"
    static let citransparency = "transparency"
    static let cifilesize = "filesize"
}

struct Deviaton
{
    let deviationid: UUID
    let title: String?
    let author_username: String?
    let content: Content?
    
    init?(_ json:Dictionary<String,Any>)
    {
        guard let deviationidString = json[Deviaton.cideviationid] as? String
              ,let deviationid = UUID(uuidString: deviationidString)
        else
        {
            assertionFailure("\(#function): failed to create instance with \(json)")
            return nil
        }
        
        self.deviationid = deviationid
        self.title = json[Deviaton.cititle] as? String
        self.author_username = (json[Deviaton.ciauthor] as? Dictionary<String,Any>)?[Deviaton.ciusername] as? String
        if let contentJSON = json[Deviaton.cicontent] as? Dictionary<String,Any>
        {
            self.content = Content(contentJSON)
        }
        else
        {
            self.content = nil
        }
    }
    
    static let cideviationid = "deviationid"
    static let cititle = "title"
    static let ciauthor = "author"
    static let ciusername = "username" // todo: unrelated to Deviaton object
    static let cicontent = "content"
}

struct DeviatonsQueryResult
{
    let has_more: Bool
    let next_offset: UInt16?
    let estimated_total: UInt64?
    let results: [Deviaton]

    init(has_more: Bool, next_offset: UInt16?, estimated_total: UInt64?, results: [Deviaton])
    {
        self.has_more = has_more
        self.next_offset = next_offset
        self.estimated_total = estimated_total
        self.results = results
    }
    
    // workaround for AFDataResponse<DeviatonsQueryResult>
    fileprivate init ()
    {
        self.init(has_more: false, next_offset: nil, estimated_total: nil, results: [])
    }
    
    fileprivate init?(_ json:Dictionary<String,Any>)
    {
        guard let has_more = json[DeviatonsQueryResult.cihas_more] as? Bool, let resultsJSON = json[DeviatonsQueryResult.ciresults] as? Array<Dictionary<String,Any>>
        else
        {
            assertionFailure("\(#function): failed to create instance with \(json)")
            return nil
        }
        
        // todo: differenciate between no value and failure co convert
        let next_offset = json[DeviatonsQueryResult.cinext_offset] as? UInt16
        let estimated_total = json[DeviatonsQueryResult.ciestimated_total] as? UInt64
        
        var results: [Deviaton] = []
        for result in resultsJSON
        {
            if let deviaton = Deviaton(result)
            {
                results.append(deviaton)
            }
        }
        
        self.init(has_more: has_more, next_offset: next_offset, estimated_total: estimated_total, results: results)
    }
    
    func withLatest(_ deviatonsQueryResult: DeviatonsQueryResult) -> DeviatonsQueryResult
    {
        var results: [Deviaton] = []
        results.reserveCapacity(self.results.count + deviatonsQueryResult.results.count)
        results.append(contentsOf: self.results)
        results.append(contentsOf: deviatonsQueryResult.results)
        
        return DeviatonsQueryResult(has_more: deviatonsQueryResult.has_more, next_offset: deviatonsQueryResult.next_offset, estimated_total: deviatonsQueryResult.estimated_total, results: results)
    }
    
    static let cihas_more = "has_more"
    static let cinext_offset = "next_offset"
    static let ciestimated_total = "estimated_total"
    static let ciresults = "results"
}

class DAManager
{
    static let shared = DAManager()
    private init() {} // please use shared
    
    private let responseQuenue = DispatchQueue.global(qos: .default)
    
    /*
        session access token
     */
    private var access_token = ""
    let sessionTokenStatus = ReplaySubject<Status>.create(bufferSize: 1)
    
    func requestAccessToken()
    {
        var urlComponents = URLComponents(string: Endpoints.accessTokenURL)!
        urlComponents.queryItems =
        [
            URLQueryItem(name: qiclient_id, value: client_id),
            URLQueryItem(name: qiclient_secret, value: client_secret),
            URLQueryItem(name: qigrant_type, value: "client_credentials"),
        ]
        
        AlamofireManager.sharedSession.request(urlComponents.url!)
            .responseJSON(queue: responseQuenue, completionHandler:
        { [weak self] (response) in
            
            guard let self = self else { return }
            
            switch (response.result)
            {
            case .success(let jsonResponse):
                if let jsonResponse = jsonResponse as? NSDictionary, let access_token = jsonResponse["access_token"] as? String, response.response?.statusCode == 200
                {
                    self.access_token = access_token
                    self.sessionTokenStatus.on(.next(.Success))
                }
                else
                {
                    print("\(#file): \(#function) line \(#line): response: \(jsonResponse)")
                    self.sessionTokenStatus.on(.next(.Error))
                }
            case .failure(let error):
                print("\(#file): \(#function) line \(#line): error: \(error)")
                self.sessionTokenStatus.on(.next(.Error))
            }
        })
    }
    
    
    enum Timerange: String
    {
        case _8hr = "8hr"
        case _24hr = "24hr"
        case _3days = "3days"
        case _1week = "1week"
        case _1month = "1month"
        case _alltime = "alltime"
    }
    
    /// Request popular deviations
    ///
    /// - Parameters:
    ///   - completion: Result callback
    ///   - offset: The pagination offset. min: `0` max: `50000` default: `0`
    ///   - timerange: The timerange. valid values(`8hr`, `24hr`, `3days`, `1week`, `1month`, `alltime`) default: `alltime`
    ///   - limit: The pagination limit. min: `1` max: `120` default: `120`
    /// - Returns:       todo
    func requestPopularDeviations(completion: @escaping (AFDataResponse<DeviatonsQueryResult>) -> Void, _ offset: UInt16 = 0, _ timerange: Timerange = ._alltime, _ limit: UInt8 = 120)
    {
        if (offset > 50000 || 1 > limit || limit > 120 || access_token.isEmpty)
        {
            preconditionFailure("offset: \(offset), limit: \(limit), access_token: \(access_token)");
        }
        
        var urlComponents = URLComponents(string: Endpoints.popular)!
        urlComponents.queryItems =
            [
                 URLQueryItem(name: qiaccess_token, value: access_token)
                ,URLQueryItem(name: qioffset, value: String(offset))
                ,URLQueryItem(name: qitimerange, value: timerange.rawValue)
                ,URLQueryItem(name: qilimit, value: String(limit))
//                ,URLQueryItem(name: "q", value: "westworld2")
            ]
        
        AlamofireManager.sharedSession.request(urlComponents.url!)
            .responseJSON(queue: responseQuenue, completionHandler:
        { (response) in
            
            switch (response.result)
            {
            case .success(let jsonResponseRaw):
                
                guard let jsonResponse = jsonResponseRaw as? Dictionary<String, Any> else {
                    let result: AFResult<DeviatonsQueryResult> = Result
                    {
                        throw AFError.responseSerializationFailed(reason: AFError.ResponseSerializationFailureReason.customSerializationFailed(error: DAError.ResponseCastFailedFor(jsonResponseRaw)))
                    }.mapError { error in
                        error.asAFError!
                    }
                    
                    completion(AFDataResponse<DeviatonsQueryResult>(request: response.request, response: response.response, data: response.data, metrics: response.metrics, serializationDuration: response.serializationDuration, result: result))
                    
                    return
                }
                
                guard response.response?.statusCode == 200 else {
                    let result: AFResult<DeviatonsQueryResult> = Result
                    {
                        throw AFError.responseValidationFailed(reason: AFError.ResponseValidationFailureReason.customValidationFailed(error: DAError.ResponseReportedError(code: response.response?.statusCode, jsonResponse)))
                    }.mapError { error in
                        error.asAFError!
                    }
                    
                    completion(AFDataResponse<DeviatonsQueryResult>(request: response.request, response: response.response, data: response.data, metrics: response.metrics, serializationDuration: response.serializationDuration, result: result))
                    
                    return
                }
                
                if let deviatonsQueryResult = DeviatonsQueryResult(jsonResponse)
                {
                    completion(response.map(
                    { (_) in
                        return deviatonsQueryResult
                    }))
                }
                else
                {
                    let result: AFResult<DeviatonsQueryResult> = Result
                    {
                        throw AFError.responseSerializationFailed(reason: AFError.ResponseSerializationFailureReason.customSerializationFailed(error: DAError.CustomSerializationFailed))
                    }.mapError { error in
                        error.asAFError!
                    }
                    
                    completion(AFDataResponse<DeviatonsQueryResult>(request: response.request, response: response.response, data: response.data, metrics: response.metrics, serializationDuration: response.serializationDuration, result: result))
                }
            case .failure(let error):
                print("\(#file): \(#function) line \(#line): error: \(error)")
                completion(response.map(
                { (_) in
                    return DeviatonsQueryResult()
                }))
            }
        })
    }
}
