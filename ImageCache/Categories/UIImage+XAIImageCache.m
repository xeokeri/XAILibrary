//
//  UIImage+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImage+XAIImageCache.h"

/** XAIImageCache */
#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDefines.h"
#import "NSString+XAIImageCache.h"

/** XAIUtilities */
#import "UIImage+XAIUtilities.h"

/** XAILogging */
#import "NSError+XAILogging.h"

@implementation UIImage (XAIImageCache)

- (void)cropIntoTilesWithSize:(CGSize)tileSize withCacheURLPrefix:(NSString *)prefix {
    NSDate *startDate;
    
    if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 0) {
        startDate = [NSDate date];
    }
    
    NSUInteger
        rows    = ceil(self.size.height / tileSize.height),
        columns = ceilf(self.size.width / tileSize.width);
    
    for (NSUInteger x = 0; x < columns; x++) {
        for (NSUInteger y = 0; y < rows; y++) {
            CGFloat
                xAxis  = floorf(x * tileSize.width),
                yAxis  = floorf(y * tileSize.height),
                width  = floorf(tileSize.width - MAX(((xAxis + tileSize.width) - self.size.width), 0.0f)),
                height = floorf(tileSize.height - MAX(((yAxis + tileSize.height) - self.size.height), 0.0f));
            
            if (width == 0.0f || height == 0.0f) {
                continue;
            }
            
            CGRect sliceFrame  = CGRectMake(xAxis, yAxis, width, height);
            NSString *sliceURL = [prefix cachedURLForImageRect:sliceFrame];
            
            if (![[XAIImageCacheStorage sharedStorage] cachedImageForURL:sliceURL]) {
                /** Crop the image slice. */
                UIImage *slicedImage = [self cropInRect:sliceFrame];
                
                /** Save slice to image cache. */
                [[XAIImageCacheStorage sharedStorage] saveImage:slicedImage forURL:sliceURL inMemory:YES];
            }
        }
    }
    
    if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 0) {
        NSTimeInterval timeSince = [[NSDate date] timeIntervalSinceDate:startDate];
        
        NSLog(@"Time: %f for %s", timeSince, __PRETTY_FUNCTION__);
    }
    
    startDate = nil;
}

@end
