//
//  UITableView+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai on 4/11/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XAIImageCacheDelegate.h"

@protocol XAIImageCacheDelegate;

@interface UITableView (XAIImageCache)

- (void)imageWithURL:(NSString *)url atIndexPath:(NSIndexPath *)indexPath delegate:(id <XAIImageCacheDelegate>)incomingDelegate size:(CGSize)imageSize;

@end
