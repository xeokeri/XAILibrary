//
//  NSString+XAIUtilities.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/28/14.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "NSString+XAIUtilities.h"
#import "NSURL+XAIUtilities.h"

#import <CommonCrypto/CommonCrypto.h>

@implementation NSString (XAIUtilities)

#pragma mark - Application's Documents Directory

/**
 Returns the base path to the applications's Document directory. (For use with prepoplated SQLite file)
 */

+ (NSString *)applicationPathForFileName:(NSString *)fileName ofType:(NSString *)fileType {
    NSString *storePath        = [[[[NSURL applicationDocumentsDirectory] URLByAppendingPathComponent:fileName] URLByAppendingPathExtension:fileType] absoluteString];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error             = nil;
    
    if (![fileManager fileExistsAtPath:storePath]) {
        NSString *defaultStorePath = [[NSBundle mainBundle] pathForResource:fileName ofType:fileType];
        
        if (defaultStorePath) {
            if (![fileManager copyItemAtPath:defaultStorePath toPath:storePath error:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            }
        }
    }
    
    return storePath;
}

/**
 * MD5 Hash
 */
- (NSString *)md5HexEncode {
    const char *input = [self UTF8String];
    
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(input, strlen(input), result);
    
    NSMutableString *encryptedResult = [[NSMutableString alloc] initWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [encryptedResult appendFormat:@"%02x", result[i]];
    }
    
    return encryptedResult;
}

/**
 * SHA256 Hash
 */
- (NSString *)sha256HexEncode {
    const char *input = [self UTF8String];
    
    unsigned char result[CC_SHA256_DIGEST_LENGTH];
    
    CC_SHA256(input, strlen(input), result);
    
    NSMutableString *encryptedResult = [[NSMutableString alloc] initWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [encryptedResult appendFormat:@"%02x", result[i]];
    }
    
    return encryptedResult;
}

@end
