//
//  AppDelegate.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 05.12.2020.
//

import UIKit
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate
{
    var window: UIWindow?

    let disposeBag = DisposeBag()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
    {
        DAManager.shared.sessionTokenStatus.asObservable().subscribe(
                onNext: { event in
                    switch (event) {
                        case .Success:
                            showStatus("Access Token status ✅", .success)
                        case .Error:
                            showStatus("Access Token status ❌", .error)
                        default: break
                    }

                }).disposed(by: disposeBag)

        showStatus("Requesting session Access Token", .info)
        DAManager.shared.requestAccessToken()

        // Override point for customization after application launch.
        return true
    }

}

