//
//  UniqueLock.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 06.12.2020.
//

import Foundation

//@available(iOS 2.0, *)
//public func objc_sync_enter(_ obj: Any) -> Int32
//
///**
// * End synchronizing on 'obj'.
// *
// * @param obj The object to end synchronizing on.
// *
// * @return OBJC_SYNC_SUCCESS or OBJC_SYNC_NOT_OWNING_THREAD_ERROR
// */
//@available(iOS 2.0, *)
//public func objc_sync_exit(_ obj: Any) -> Int32

// reqursive lock
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
