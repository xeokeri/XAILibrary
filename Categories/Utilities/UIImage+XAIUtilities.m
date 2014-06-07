//
//  UIImage+XAIUtilities.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 12/9/11.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImage+XAIUtilities.h"

#import <QuartzCore/QuartzCore.h>
#import <ImageIO/ImageIO.h>

#define kXAIUtilitiesMaxImageSize   1024.0f

@interface UIImage (XAIUtilitiesPrivate)

- (CGSize)rotateSize:(CGSize)size;
+ (CGFloat)maxSide;

@end

@implementation UIImage (XAIUtilitiesPrivate)

- (CGSize)rotateSize:(CGSize)size {
    return CGSizeMake(size.height, size.width);
}

+ (CGFloat)maxSide {
    return floorf(kXAIUtilitiesMaxImageSize * [[UIScreen mainScreen] scale]);
}

@end

@implementation UIImage (XAIUtilities)

#pragma mark - UIView Capture

/** @todo Fix issue with retina clipping. */
+ (UIImage *)createImageFromView:(UIView *)captureView {
    UIGraphicsBeginImageContextWithOptions(captureView.bounds.size, captureView.opaque, 0.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    [captureView.layer renderInContext:context];
    
    UIImage *capturedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return capturedImage;
}

#pragma mark - UIImage Crop

- (UIImage *)cropInRect:(CGRect)rect {
    if (self.scale > 1.0f) {
        rect = CGRectMake((rect.origin.x * self.scale), (rect.origin.y * self.scale), (rect.size.width * self.scale), (rect.size.height * self.scale));
    }
    
    CGImageRef referenceImage = CGImageCreateWithImageInRect(self.CGImage, rect);
    UIImage *croppedImage     = [UIImage imageWithCGImage:referenceImage scale:self.scale orientation:UIImageOrientationUp];
    
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

#pragma mark - UIImage Scale

- (UIImage *)scaleAspectRatioToMaxTileSize {
    UIImage *resizedImage = nil;
    
    CGFloat
        imageScale    = [[UIScreen mainScreen] scale],
        maxTileSize   = [UIImage maxSide];
    
    /** The starting aspect size. */
    CGSize aspectSize = CGSizeMake(floorf(self.size.width / imageScale), floorf(self.size.height / imageScale));
    
    /** Check if size of original image is less than max pixels. */
    if (self.size.width > maxTileSize || self.size.height > maxTileSize) {
        CGFloat
            aspectWidth  = (((self.size.width / self.size.height) * maxTileSize) / imageScale),
            aspectHeight = (((self.size.height / self.size.width) * maxTileSize) / imageScale),
            maxWidth     = ceilf(sqrt(aspectWidth) * sqrt(aspectHeight));
        
        /** Resize accordingly to make the aspect stay the same. */
        aspectSize = CGSizeMake(maxWidth, aspectHeight);
    }
    
    CGRect imageFrame = {CGPointZero, aspectSize};
    
    @autoreleasepool {
        UIGraphicsBeginImageContextWithOptions(aspectSize, YES, 0.0f);
        
        [self drawInRect:imageFrame];
        
        resizedImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return resizedImage;
}

#pragma mark - UIImage Resize

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
        imageResolution.width  = floorf((minSideLength / height * width) * scale);
        imageResolution.height = floorf(minSideLength * scale);
    } else {
        imageResolution.width  = floorf(minSideLength * scale);
        imageResolution.height = floorf((minSideLength / width * height) * scale);
    }
    
    CGRect imageFrame = CGRectMake(0.0f, 0.0f, imageResolution.width, imageResolution.height);
    
    UIGraphicsBeginImageContext(imageResolution);
    
    [self drawInRect:imageFrame];
    
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

#pragma mark - UIImage Overlay

- (UIImage *)colorOverlay:(UIColor *)color {
    CGRect bounds = {0.0f, 0.0f, self.size};
    
    /** Allow transparent images to show accordingly. */
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    
    /** Overlay the image with the selected color. */
    [color setFill];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextTranslateCTM(context, 0.0f, self.size.height);
    CGContextScaleCTM(context, 1.0f, -1.0f);
    CGContextClipToMask(context, bounds, [self CGImage]);
    CGContextAddRect(context, bounds);
    CGContextDrawPath(context, kCGPathFill);
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return overlayImage;
}

#pragma mark - UIImage Rotate & Scale

+ (UIImage *)resizedCachedImageWithFilePath:(NSURL *)imagePath {
    UIImage *resizedImage      = nil;
    CGImageSourceRef imgSource = CGImageSourceCreateWithURL((__bridge CFURLRef)imagePath, NULL);
    
    if (!imgSource) {
        return nil;
    }
    
    @autoreleasepool {
        CFDictionaryRef imageOptions = (__bridge CFDictionaryRef) @{
            (id)kCGImageSourceCreateThumbnailWithTransform: (id)kCFBooleanTrue,
            (id)kCGImageSourceCreateThumbnailFromImageIfAbsent: (id)kCFBooleanTrue,
            (id)kCGImageSourceThumbnailMaxPixelSize: (id)@([UIImage maxSide])
        };
        
        CGImageRef imageRef = CGImageSourceCreateThumbnailAtIndex(imgSource, 0, imageOptions);
        
        resizedImage = [UIImage imageWithCGImage:imageRef];
        
        CGImageRelease(imageRef);
        CFRelease(imgSource);
    }
    
    return resizedImage;
}

@end
