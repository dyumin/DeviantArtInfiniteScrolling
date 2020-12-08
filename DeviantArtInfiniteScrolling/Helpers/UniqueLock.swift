//
//  UniqueLock.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import Foundation

// reqursive unique lock
class UniqueLock
{
    private var isOwningLock = true
    let obj: AnyObject
    
    init(_ obj: AnyObject)
    {
        self.obj = obj
        objc_sync_enter(obj)
    }
    
    @discardableResult
    init(_ obj: AnyObject, _ trailingClosure : () -> Void)
    {
        self.obj = obj
        objc_sync_enter(obj)
        trailingClosure()
        unlockImpl()
    }
    
    deinit
    {
        unlockImpl()
    }
    
    private func unlockImpl()
    {
        if (isOwningLock)
        {
            objc_sync_exit(obj)
            isOwningLock = false
        }
    }
    
    func unlock()
    {
        unlockImpl()
    }
}
