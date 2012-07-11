//
//  UIImage+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"
#import "XAIImageCacheDefines.h"

#import "XAIImageCacheStorage.h"

/** XAILogging */
#import "NSError+XAILogging.h"

@implementation UIImage (XAIImageCache)

+ (UIImage *)cachedImageForURL:(NSString *)imageURL {
    NSError *error       = nil;
    NSArray *cachePath   = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imagePath  = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
    NSData *imageData    = [NSData dataWithContentsOfFile:imagePath options:NSDataReadingMappedIfSafe error:&error];
    
    if (error != nil) {
        switch ([error code]) {
            case NSFileReadNoSuchFileError: {
                if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 1) {
                    NSLog(@"File not found for cache URL: %@", imageURL);
                }
            }
                
                break;
                
            default: {
                [error logDetailsFailedOnSelector:_cmd line:__LINE__];
            }
                
                break;
        }
        
        return nil;
    }
    
    return [UIImage imageWithData:imageData];
}

- (UIImage *)cropInRect:(CGRect)rect {
    CGImageRef referenceImage = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *croppedImage     = [UIImage imageWithCGImage:referenceImage];
    
    CGImageRelease(referenceImage);
    
    return croppedImage;
}

- (UIImage *)cropInCenterForSize:(CGSize)size {
    return [self cropInCenterForSize:size withScaling:YES];
}

- (UIImage *)cropInCenterForSize:(CGSize)size withScaling:(BOOL)scaling {
    /** Needed for retina display. */
    BOOL forcedScaleUp = !scaling;
    
    CGFloat
        scale  = [[UIScreen mainScreen] scale],
        width  = (forcedScaleUp) ? (size.width * scale) : size.width,
        height = (forcedScaleUp) ? (size.height * scale) : size.height,
        x      = floorf((self.size.width - width) * 0.5f),
        y      = floorf((self.size.height - height) * 0.5f);
    
    CGRect rect = CGRectMake(x, y, width, height);
    
    if ((scaling == YES) && (scale > 1.0f)) {
        rect = CGRectMake(floorf(x * scale), floorf(y * scale), floorf(width * scale), floorf(height * scale));
    }
    
    return [self cropInRect:rect];
}

- (void)cropIntoTilesWithSize:(CGSize)tileSize withCacheURLPrefix:(NSString *)prefix {
    NSDate *startDate;
    
    if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 1) {
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
            
            if (![UIImage cachedImageForURL:sliceURL]) {
                /** Crop the image slice. */
                UIImage *slicedImage = [self cropInRect:sliceFrame];
                
                /** Save slice to image cache. */
                [[XAIImageCacheStorage sharedStorage] saveImage:slicedImage forURL:sliceURL];
            }
        }
    }
    
    if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 1) {
        NSTimeInterval timeSince = [[NSDate date] timeIntervalSinceDate:startDate];
        
        NSLog(@"Time: %f for %s", timeSince, __PRETTY_FUNCTION__);
    }
    
    startDate = nil;
}

- (UIImage *)resizeToFillThenCropToSize:(CGSize)size {
    UIImage *resizedImage = [self resizeToFillSize:size];
    
    return [resizedImage cropInCenterForSize:size withScaling:NO];
}

- (UIImage *)resizeToFillSize:(CGSize)size {
    CGImageRef referenceImage = [self CGImage];
    
    CGFloat
        width         = CGImageGetWidth(referenceImage),
        height        = CGImageGetHeight(referenceImage),
        scale         = [[UIScreen mainScreen] scale],
        minSideLength = MIN(size.width, size.height);
    
    CGSize imageResolution = CGSizeMake(width, height);
    
    if (width >= height) {
        imageResolution.width  = ((minSideLength / height * width) * scale);
        imageResolution.height = (minSideLength * scale);
    } else {
        imageResolution.width  = (minSideLength * scale);
        imageResolution.height = ((minSideLength / width * height) * scale);
    }
    
    CGRect imageFrame = CGRectMake(0.0f, 0.0f, imageResolution.width, imageResolution.height);
    
    UIGraphicsBeginImageContext(imageResolution);
    
    [self drawInRect:imageFrame];
    
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

@end
