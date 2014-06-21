//
//  UIScrollView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/11/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "UIScrollView+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"
#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDelegate.h"

/** XAILogging */
#import "NSException+XAILogging.h"

@implementation UIScrollView (XAIImageCache)

// TODO: Refactor and remove the duplicates.
- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate {
    [self imageWithURL:url atIndexPath:indexPath delegate:incomingDelegate size:CGSizeZero];
}

- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate size:(CGSize)imageSize {
    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:incomingDelegate atIndexPath:indexPath size:imageSize];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    #if !__has_feature(objc_arc)
        [cacheOperation release];
    #endif
}

@end
