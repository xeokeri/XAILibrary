//
//  UIButton+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 2/24/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIButton+XAIImageCache.h"
#import "NSString+XAIImageCache.h"

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheOperation.h"
#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDelegate.h"

/** XAILogging */
#import "NSException+XAILogging.h"

@implementation UIButton (XAIImageCache)

+ (UIButton *)buttonWithURL:(NSString *)url {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.imageView.contentMode = UIViewContentModeScaleAspectFit;
    button.imageView.hidden      = NO;
    
    XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:button];
    
    [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
    
    #if !__has_feature(objc_arc)
        [cacheOperation release];
    #endif
    
    return button;
}

- (void)imageWithURL:(NSString *)url {
    [self imageWithURL:url resize:YES];
}

- (void)imageWithURL:(NSString *)url resize:(BOOL)resizeImage {
    [[XAIImageCacheStorage sharedStorage] cacheCleanup];
    
    [self setImage:nil forState:UIControlStateNormal];
    
    [self setAdjustsImageWhenHighlighted:YES];
    
    CGSize cacheSize   = self.frame.size;
    CGFloat cacheScale = [[UIScreen mainScreen] scale];
    
    if (cacheScale > 1.0f) {
        cacheSize.width  = floorf(cacheSize.width * cacheScale);
        cacheSize.height = floorf(cacheSize.height * cacheScale);
    }
    
    NSString *cacheURL   = (resizeImage) ? [url cachedURLForImageSize:cacheSize] : url;
    UIImage *cachedImage = [[XAIImageCacheStorage sharedStorage] cachedImageForURL:cacheURL];
    
    if (cachedImage) {
        @try {
            [self setHidden:NO];
            
            if ([self respondsToSelector:@selector(processCachedImage:)]) {
                [self performSelector:@selector(processCachedImage:) withObject:cachedImage];
            } else {
                [self setImage:cachedImage forState:UIControlStateNormal];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    } else {
        self.hidden          = YES;
        self.alpha           = 0.0f;
        
        XAIImageCacheOperation *cacheOperation = [[XAIImageCacheOperation alloc] initWithURL:url delegate:self resize:resizeImage];
        
        [[XAIImageCacheQueue sharedQueue] addOperation:cacheOperation];
        
        #if !__has_feature(objc_arc)
            [cacheOperation release];
        #endif
    }
}

@end
