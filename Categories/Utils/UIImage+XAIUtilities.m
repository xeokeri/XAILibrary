//
//  UIImage+XAIUtilities.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 12/9/11.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "UIImage+XAIUtilities.h"

@implementation UIImage (XAIUtilities)

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

- (UIImage *)colorOverlay:(UIColor *)color {
    CGRect bounds = {0.0f, 0.0f, self.size};
    
    UIGraphicsBeginImageContext(self.size);
    
    /** Overlay the image with the selected color. */
    [color setFill];
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextClipToMask(context, bounds, [self CGImage]);
    CGContextFillRect(context, bounds);
    
    UIImage *overlayImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return overlayImage;
}

@end
