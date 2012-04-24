//
//  UIImage+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "XAIImageCacheDefines.h"

@interface UIImage (XAIImageCache)

/** XAIImageCache Image Checking. */
+ (UIImage *)cachedImageForURL:(NSString *)imageURL;

/** UIImage Crop. */
- (UIImage *)cropInCenterForSize:(CGSize)size;
- (UIImage *)cropInCenterForSize:(CGSize)size withScaling:(BOOL)scaling;

/** UIImage Resize. */
- (UIImage *)resizeToFillThenCropToSize:(CGSize)size;
- (UIImage *)resizeToFillSize:(CGSize)size;

@end
