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

@implementation UIImage (XAIImageCache)

+ (UIImage *)cachedImageForURL:(NSString *)imageURL {
    NSArray *cachePath  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imagePath = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
    NSData *imageData   = [NSData dataWithContentsOfFile:imagePath];
    
    return [UIImage imageWithData:imageData];
}

- (UIImage *)cropInRect:(CGRect)rect {
    CGImageRef referenceImage = CGImageCreateWithImageInRect([self CGImage], rect);
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

- (NSArray *)sliceIntoNumberOfPieces:(NSUInteger)pieces withCacheURLPrefix:(NSString *)prefix {
    NSDate *startDate      = [NSDate date];
    NSMutableArray *panels = [NSMutableArray arrayWithCapacity:pieces];
    
    CGFloat
        square      = floorf(sqrtf((float) pieces)),
        imageWidth  = floorf(self.size.width),
        imageHeight = floorf(self.size.height),
        maxWidth    = floorf(self.size.width),
        maxHeight   = floorf(self.size.height);
    
    if (((int) imageHeight) % 2 == 1) {
        imageHeight += 1;
    }
    
    if (floorf(imageHeight / square) != (imageHeight / square)) {
        imageHeight += 2.0f;
    }
    
    CGFloat
        pixelsForImage = floorf(imageWidth * imageHeight),
        pixelsPerPanel = (pixelsForImage / square),
        width  = (pixelsPerPanel / imageHeight),
        height = (pixelsPerPanel / imageWidth),
        xAxis  = 0.0f,
        yAxis  = 0.0f;
    
    
    if (kXAIImageCacheSliceDebugging) {
        NSLog(@"Pieces: %d, Square: %f, Width: %f, Height: %f", pieces, square, width, height);
    }
    
    NSUInteger maxPanelsPerRow = (NSUInteger) square;
    
    
    for (NSUInteger i = 0; i < pieces; i++) {
        CGFloat
            frameWidth  = width,
            frameHeight = height;
        
        if (i > 0) {
            if (i % maxPanelsPerRow == 0) {
                yAxis += height;
            }
            
            xAxis += width;
            
            if (xAxis >= floorf(width * maxPanelsPerRow)) {
                xAxis = 0.0f;
            }
        }
        
        if ((xAxis + width) > maxWidth) {
            frameWidth -= floorf((xAxis + width) - maxWidth);
        }
        
        if ((yAxis + frameHeight) > maxHeight) {
            frameHeight -= floorf((yAxis + height) - maxHeight);
        }
        
        CGRect sliceFrame  = CGRectMake(xAxis, yAxis, frameWidth, frameHeight);
        NSString *sliceURL = [prefix cachedURLForImageRect:sliceFrame];
        
        if (![UIImage cachedImageForURL:sliceURL]) {
            /** Crop the image slice. */
            UIImage *slicedImage = [self cropInRect:sliceFrame];
            
            /** Save slice to image cache. */
            [[XAIImageCacheStorage sharedStorage] saveImage:slicedImage forURL:sliceURL];
        }
        
        /** Add cache URL. */
        [panels addObject:sliceURL];
    }
    
    if (kXAIImageCacheSliceDebugging) {
        NSTimeInterval timeSince = [[NSDate date] timeIntervalSinceDate:startDate];
        
        NSLog(@"Time: %f for %s", timeSince, __PRETTY_FUNCTION__);
    }
    
    return [NSArray arrayWithArray:panels];
}

@end
