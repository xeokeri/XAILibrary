//
//  UIImage+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImage+XAIImageCache.h"
#import "NSString+XAIImageCache.h"
#import "XAIImageCacheDefines.h"

@implementation UIImage (XAIImageCache)

+ (UIImage *)cachedImageForURL:(NSString *)imageURL {
    NSArray *cachePath  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imagePath = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
    NSData *imageData   = [NSData dataWithContentsOfFile:imagePath];
    
    return [UIImage imageWithData:imageData];
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
    
    CGImageRef referenceImage = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *croppedImage     = [UIImage imageWithCGImage:referenceImage];
    
    CGImageRelease(referenceImage);
    
    return croppedImage;
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
