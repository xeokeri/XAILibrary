//
//  NSString+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGGeometry.h>

@interface NSString (XAIImageCache)

- (NSString *)cachedURLForImageSize:(CGSize)imageSize;
- (NSString *)cachedURLForImageRect:(CGRect)imageRect;

@end
