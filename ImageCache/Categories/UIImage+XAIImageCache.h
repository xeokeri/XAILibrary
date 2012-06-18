//
//  UIImage+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XAIImageCacheDefines.h"

@interface UIImage (XAIImageCache)

/** XAIImageCache Image Checking */
+ (UIImage *)cachedImageForURL:(NSString *)imageURL;

/** UIImage Crop */
- (UIImage *)cropInRect:(CGRect)rect;
- (UIImage *)cropInCenterForSize:(CGSize)size;
- (UIImage *)cropInCenterForSize:(CGSize)size withScaling:(BOOL)scaling;

/** UIImage Resize */
- (UIImage *)resizeToFillThenCropToSize:(CGSize)size;
- (UIImage *)resizeToFillSize:(CGSize)size;

/** UIImage Slice */
- (NSArray *)sliceIntoNumberOfPieces:(NSUInteger)pieces withCacheURLPrefix:(NSString *)prefix;

@end
