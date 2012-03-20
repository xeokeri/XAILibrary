//
//  UIImageView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImageView+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheQueue.h"

#import "NSException+Customized.h"

@implementation UIImageView (XAIImageCache)

+ (UIImageView *)imageViewWithURL:(NSString *)imageURL {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:nil];
    
    imageView.alpha  = 0.0f;
    imageView.hidden = YES;

    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:imageURL withImageViewDelegate:imageView];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    [cacheOperation release];
    
    return [imageView autorelease];
}

- (void)imageWithURL:(NSString *)imageURL {
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    self.alpha  = 0.0f;
    self.hidden = YES;
    self.image  = nil;
    
    UIImage *cachedImage = [UIImage cachedImageForURL:imageURL];
    
    if (cachedImage) {
        @try {
            [UIView beginAnimations:@"LoadCachedImage" context:nil];
            
            self.image = cachedImage;
            self.hidden = NO;
            self.alpha  = 1.0f;
            
            [UIView commitAnimations];
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    } else {
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:imageURL withImageViewDelegate:self];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        [cacheOperation release];
    }
}

@end
