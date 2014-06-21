//
//  UIScrollView+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/11/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XAIImageCacheDelegate.h"

@protocol XAIImageCacheDelegate;

@interface UIScrollView (XAIImageCache)

- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate;
- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate size:(CGSize)imageSize;

@end
