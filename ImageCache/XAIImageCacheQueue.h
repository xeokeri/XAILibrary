//
//  XAIImageCacheQueue.h
//  XAIImageCache
//
//  Created by Xeon Xai on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAIImageCacheQueue : NSOperationQueue {
    
}

+ (XAIImageCacheQueue *)sharedQueue;
- (void)cacheCleanup;

@end
