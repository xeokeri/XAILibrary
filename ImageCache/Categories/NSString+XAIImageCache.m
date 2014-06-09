//
//  NSString+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "NSString+XAIImageCache.h"

@implementation NSString (XAIImageCache)

/** For use with resized images. */
- (NSString *)cachedURLForImageSize:(CGSize)imageSize {
    return [NSString stringWithFormat:@"%@?width=%.2f&height=%.2f", self, floorf(imageSize.width), floorf(imageSize.height)];
}

/** For use with sliced images. */
- (NSString *)cachedURLForImageRect:(CGRect)imageRect {
    return [NSString stringWithFormat:@"%@?x=%.2f&y=%.2f&width=%.2f&height=%.2f", self, floorf(CGRectGetMinX(imageRect)), floorf(CGRectGetMinY(imageRect)), floorf(CGRectGetWidth(imageRect)), floorf(CGRectGetHeight(imageRect))];
}

@end
