//
//  NSString+XAIImageCache.m
//  XAIImageCache
//
//  Created by Xeon Xai on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "NSString+XAIImageCache.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (XAIImageCache)

- (NSString *)md5HexEncode {
    const char *input = [self UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(input, strlen(input), result);
    
    NSMutableString *encryptedResult = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [encryptedResult appendFormat:@"%02x", result[i]];
    }
    
    return encryptedResult;
}

- (NSString *)cachedURLForImageSize:(CGSize)imageSize {
    return [NSString stringWithFormat:@"%@+%@", self, NSStringFromCGSize(imageSize)];
}

@end
