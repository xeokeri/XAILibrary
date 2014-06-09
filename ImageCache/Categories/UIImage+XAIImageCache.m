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

#pragma mark - BOOL

- (BOOL)cropIntoTilesWithSize:(CGSize)tileSize withCacheURLPrefix:(NSString *)prefix {
    return [self cropIntoTilesWithSize:tileSize withCacheURLPrefix:prefix overflowEdges:NO];
}

- (BOOL)cropIntoTilesWithSize:(CGSize)tileSize withCacheURLPrefix:(NSString *)prefix overflowEdges:(BOOL)overflowEdges {
    NSDate *startDate = nil;
    BOOL successful   = YES;
    
    if (XAIImageCacheDebuggingLevelCurrentState >= XAIImageCacheDebuggingLevelLow) {
        startDate = [NSDate date];
    }
    
    NSUInteger
        rows    = ceilf(self.size.height / tileSize.height),
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
            
            if (overflowEdges == YES) {
                /** Check to expand the width and height for the tile frame. */
                for (NSUInteger z = 0; z <= 1; z++) {
                    /** Move the width upwards. */
                    if (floorf((xAxis - XAIImageCacheCropEdgeOverflow) + width) < floorf(self.size.width)) {
                        if (floorf(xAxis) == 0.0f && z > 0) {
                            continue;
                        }
                        
                        width += XAIImageCacheCropEdgeOverflow;
                    }
                    
                    /** Move the height upwards. */
                    if (floorf((yAxis - XAIImageCacheCropEdgeOverflow) + height) < floorf(self.size.height)) {
                        if (floorf(yAxis) == 0.0f && z > 0) {
                            continue;
                        }
                        
                        height += XAIImageCacheCropEdgeOverflow;
                    }
                }
                
                /** Move the X axis back. */
                if (floorf(xAxis - XAIImageCacheCropEdgeOverflow) > 0.0f) {
                    xAxis -= XAIImageCacheCropEdgeOverflow;
                }
                
                /** Move the Y axis back. */
                if (floorf(yAxis - XAIImageCacheCropEdgeOverflow) > 0.0f) {
                    yAxis -= XAIImageCacheCropEdgeOverflow;
                }
            }
            
            CGRect sliceFrame  = CGRectMake(xAxis, yAxis, width, height);
            NSString *sliceURL = [prefix cachedURLForImageRect:sliceFrame];
            
            if (![[XAIImageCacheStorage sharedStorage] cachedImageForURL:sliceURL]) {
                /** Crop the image slice. */
                UIImage *slicedImage = [self cropInRect:sliceFrame];
                
                /** Save slice to image cache. */
                BOOL savedImage = [[XAIImageCacheStorage sharedStorage] saveImage:slicedImage forURL:sliceURL];
                
                slicedImage = nil;
                
                if (!savedImage) {
                    successful = NO;
                    
                    if (XAIImageCacheDebuggingLevelCurrentState >= XAIImageCacheDebuggingLevelLow) {
                        NSLog(@"Image not saved for URL: %@", sliceURL);
                    }
                }
            }
        }
    }
    
    if (XAIImageCacheDebuggingLevelCurrentState >= XAIImageCacheDebuggingLevelLow) {
        NSTimeInterval timeSince = [[NSDate date] timeIntervalSinceDate:startDate];
        
        NSLog(@"Time: %f for %s", timeSince, __PRETTY_FUNCTION__);
    }
    
    startDate = nil;
    
    return successful;
}

@end
