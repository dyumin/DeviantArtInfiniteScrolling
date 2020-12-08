//
//  ExceptionCatcher.h
//  DeviantArtInfiniteScrolling
//
//  Created by El D on 08.12.2020.
//

#ifndef ExceptionCatcher_h
#define ExceptionCatcher_h

#import <Foundation/Foundation.h>  

NS_INLINE NSException * _Nullable tryBlock(void(^_Nonnull tryBlock)(void)) {
    @try {
        tryBlock();
    }
    @catch (NSException *exception) {
        return exception;
    }
    return nil;
}

#endif /* ExceptionCatcher_h */
