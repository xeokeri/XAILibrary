//
//  UIImageView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImageView+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheQueue.h"

#import "NSException+Customized.h"

@implementation UIImageView (XAIImageCache)

+ (UIImageView *)imageViewWithURL:(NSString *)imageURL {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:nil];
    
    imageView.alpha  = 0.0f;
    imageView.hidden = YES;

    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:imageURL delegate:imageView];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    [cacheOperation release];
    
    return [imageView autorelease];
}

- (void)imageWithURL:(NSString *)url {
    [self imageWithURL:url resize:YES];
}

- (void)imageWithURL:(NSString *)url resize:(BOOL)resizeImage {
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    NSString *cacheURL   = (resizeImage) ? [url cachedURLForImageSize:self.frame.size] : url;
    UIImage *cachedImage = [UIImage cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            self.image  = cachedImage;
            self.hidden = NO;
            self.alpha  = 1.0f;
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    } else {
        self.alpha  = 0.0f;
        self.hidden = YES;
        self.image  = nil;
        
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self resize:resizeImage];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        [cacheOperation release];
    }
}

@end
