//
//  UIButton+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIButton+XAIImageCache.h"
#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"

@implementation UIButton (XAIImageCache)

+ (UIButton *)buttonWithURL:(NSString *)imageURL {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.imageView.hidden      = NO;
    
    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:imageURL withImageViewDelegate:button.imageView];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    [cacheOperation release];
    
    return button;
}

@end
