//
//  UIScrollView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 6/6/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIScrollView+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"
#import "NSException+XAILogging.h"

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"
#import "XAIImageCacheDelegate.h"

@implementation UIScrollView (XAIImageCache)

- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate {
    [self imageWithURL:url atIndexPath:indexPath delegate:incomingDelegate size:CGSizeZero];
}

- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate size:(CGSize)imageSize {
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    NSString *cacheURL   = (imageSize.width != CGSizeZero.width && imageSize.height != CGSizeZero.height) ? [url cachedURLForImageSize:imageSize] : url;
    UIImage *cachedImage = [UIImage cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            if ([incomingDelegate respondsToSelector:@selector(processCachedImage:atIndexPath:)]) {
                [incomingDelegate processCachedImage:cachedImage atIndexPath:indexPath];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    } else {
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:incomingDelegate atIndexPath:indexPath size:imageSize];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        #if !__has_feature(objc_arc)
            [cacheOperation release];
        #endif
    }
}

@end
