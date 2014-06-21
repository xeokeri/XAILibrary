//
//  UIImageView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "UIImageView+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheQueue.h"
#import "XAIImageCacheStorage.h"

/** XAILogging */
#import "NSException+XAILogging.h"

@implementation UIImageView (XAIImageCache)

+ (UIImageView *)imageViewWithURL:(NSString *)imageURL {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:nil];
    
    imageView.alpha  = 0.0f;
    imageView.hidden = YES;

    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:imageURL delegate:imageView size:CGSizeZero];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    #if !__has_feature(objc_arc)
        [cacheOperation release];
        [imageView autorelease];
    #endif
    
    return imageView;
}

- (void)imageWithURL:(NSString *)url {
    [self imageWithURL:url resize:YES];
}

- (void)imageWithURL:(NSString *)url resize:(BOOL)resizeImage {
    CGSize cacheSize   = self.frame.size;
    CGFloat cacheScale = [[UIScreen mainScreen] scale];
    
    if (cacheScale > 1.0f) {
        cacheSize.width  = floorf(cacheSize.width * cacheScale);
        cacheSize.height = floorf(cacheSize.height * cacheScale);
    }
    
    self.alpha  = 0.0f;
    self.hidden = YES;
    self.image  = nil;
    
    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self size:cacheSize];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    #if !__has_feature(objc_arc)
        [cacheOperation release];
    #endif
}

@end
