//
//  XAIImageCacheQueue.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAIImageCacheQueue : NSOperationQueue {
    @private
    NSMutableArray *urlList;
}

@property (nonatomic, retain) NSMutableArray *urlList;

+ (XAIImageCacheQueue *)sharedQueue;
- (void)cacheCleanup;
- (void)removeURL:(NSString *)url;

@end
