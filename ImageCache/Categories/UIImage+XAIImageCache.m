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

@end
