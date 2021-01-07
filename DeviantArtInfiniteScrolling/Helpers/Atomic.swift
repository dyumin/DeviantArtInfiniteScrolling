//
//  Atomic.swift
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 07.01.2021.
//  https://www.onswiftwings.com/posts/atomic-property-wrapper/
//

import Foundation

@propertyWrapper
struct Atomic<Value>
{
    private var value: Value
    private let lock = NSLock()
    
    init(wrappedValue value: Value)
    {
        self.value = value
    }
    
    var wrappedValue: Value
    {
        set
        {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
        get
        {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
    }
}
