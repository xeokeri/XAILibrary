//
//  UIImageView+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImageView+XAIImageCache.h"
#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "XAIImageCacheOperation.h"
#import "XAIImageCacheQueue.h"

#import "NSException+XAILogging.h"

@implementation UIImageView (XAIImageCache)

+ (UIImageView *)imageViewWithURL:(NSString *)imageURL {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:nil];
    
    imageView.alpha  = 0.0f;
    imageView.hidden = YES;

    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:imageURL delegate:imageView];
    
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
    [[XAIImageCacheQueue sharedQueue] cacheCleanup];
    
    CGSize cacheSize   = self.frame.size;
    CGFloat cacheScale = [[UIScreen mainScreen] scale];
    
    if (cacheScale > 1.0f) {
        cacheSize.width  = floorf(cacheSize.width * cacheScale);
        cacheSize.height = floorf(cacheSize.height * cacheScale);
    }
    
    NSString *cacheURL   = (resizeImage) ? [url cachedURLForImageSize:cacheSize] : url;
    UIImage *cachedImage = [UIImage cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            self.image  = cachedImage;
            self.hidden = NO;
            self.alpha  = 1.0f;
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    } else {
        self.alpha  = 0.0f;
        self.hidden = YES;
        self.image  = nil;
        
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self resize:resizeImage];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        #if !__has_feature(objc_arc)
            [cacheOperation release];
        #endif
    }
}

@end
