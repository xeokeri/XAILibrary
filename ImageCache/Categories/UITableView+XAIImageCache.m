//
//  UITableView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 4/11/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UITableView+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"
#import "NSException+Customized.h"

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"
#import "XAIImageCacheDelegate.h"

@implementation UITableView (XAIImageCache)

- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate size:(CGSize)imageSize {
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    NSString *cacheURL   = [url cachedURLForImageSize:imageSize];
    UIImage *cachedImage = [UIImage cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            if ([incomingDelegate respondsToSelector:@selector(processCachedImage:atIndexPath:)]) {
                [incomingDelegate processCachedImage:cachedImage atIndexPath:indexPath];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    } else {
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self atIndexPath:indexPath size:imageSize];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        [cacheOperation release];
    }
}

@end
