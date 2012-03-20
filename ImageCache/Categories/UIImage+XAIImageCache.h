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

+ (UIImage *)cachedImageForURL:(NSString *)imageURL;

@end
