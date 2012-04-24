//
//  UIButton+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIButton+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"

#import "NSException+Customized.h"

@implementation UIButton (XAIImageCache)

+ (UIButton *)buttonWithURL:(NSString *)url {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.imageView.hidden      = NO;
    
    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:button];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    [cacheOperation release];
    
    return button;
}

- (void)imageWithURL:(NSString *)url {
    [self imageWithURL:url resize:YES];
}

- (void)imageWithURL:(NSString *)url resize:(BOOL)resizeImage {
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    [self setImage:nil forState:UIControlStateNormal];
    [self setImage:nil forState:UIControlStateHighlighted];
    [self setImage:nil forState:UIControlStateSelected];
    
    NSString *cacheURL   = (resizeImage) ? [url cachedURLForImageSize:self.frame.size] : url;
    UIImage *cachedImage = [UIImage cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            [self setHidden:NO];
            
            [self setImage:cachedImage forState:UIControlStateNormal];
            [self setImage:cachedImage forState:UIControlStateHighlighted];
            [self setImage:cachedImage forState:UIControlStateSelected];
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    } else {
        self.hidden          = YES;
        self.alpha           = 0.0f;
        
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self resize:resizeImage];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        [cacheOperation release];
    }
}

@end
