//
//  XAIImageCacheStorage.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheStorage.h"
#import "XAIImageCacheDefines.h"

/** XAIImageCache Categories */
#import "NSString+XAIImageCache.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@implementation XAIImageCacheStorage

@synthesize memoryStorage;

#pragma mark - Init XAIImageCache

+ (XAIImageCacheStorage *)sharedStorage {
    static XAIImageCacheStorage *instanceStorage;
    
    @synchronized(self) {
        if (!instanceStorage) {
            NSAssert(instanceStorage == nil, @"InstanceStorage should be nil.");
            
            instanceStorage = [[self alloc] init];
            
            /** Set the memory storage. */
            [instanceStorage setMemoryStorage:[NSMutableDictionary dictionaryWithCapacity:0]];
            
            /** Create the image cache folder. */
            NSError *error             = nil;
            NSArray *cachePaths        = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *cacheFolder      = [[cachePaths lastObject] stringByAppendingPathComponent:kXAIImageCacheDirectoryPath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            if (![fileManager fileExistsAtPath:cacheFolder]) {
                [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:&error];
                
                if (error != nil) {
                    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            }
        }
    }
    
    NSAssert(instanceStorage, @"InstanceStorage should not be nil.");
    
    return instanceStorage;
}

#pragma mark - Image Cache Save

- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL {
    [self saveImage:image forURL:imageURL inMemory:NO];
}

- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL inMemory:(BOOL)inMemory {
    if (!inMemory) {
        NSData *imageData   = [NSData dataWithData:UIImagePNGRepresentation(image)];
        NSArray *cachePath  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *imagePath = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
        
        [imageData writeToFile:imagePath atomically:YES];
    } else {
        NSDictionary *imageContents = [NSDictionary dictionaryWithObject:image forKey:kXAIImageCacheMemoryImageKey];
        
        [self.memoryStorage setObject:imageContents forKey:imageURL];
    }
}

#pragma mark - Image Cache Load

- (UIImage *)cachedImageForURL:(NSString *)imageURL {
    UIImage *cachedImage = nil;
    
    @try {
        if ([self.memoryStorage count] > 0 && [[self.memoryStorage allKeys] containsObject:imageURL]) {
            NSDictionary *contents = [self.memoryStorage objectForKey:imageURL];
            
            if (contents != nil) {
                cachedImage = [contents objectForKey:kXAIImageCacheMemoryImageKey];
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    } @finally {
        if (cachedImage == nil) {
            /** Loading from disk. */
            if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2) {
                NSLog(@"Checking disk.");
            }
            
            NSError *error      = nil;
            NSArray *cachePath  = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSString *imagePath = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, kXAIImageCacheDirectoryPath, [imageURL md5HexEncode]]];
            NSData *imageData   = [NSData dataWithContentsOfFile:imagePath options:NSDataReadingMappedIfSafe error:&error];
            
            if (error != nil) {
                switch ([error code]) {
                    case NSFileReadNoSuchFileError: {
                        if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 1) {
                            NSLog(@"File not found for cache URL: %@", imageURL);
                        }
                    }
                        
                        break;
                        
                    default: {
                        [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                    }
                        
                        break;
                }
                
                return nil;
            }
            
            if (imageData != nil) {
                if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2) {
                    NSLog(@"Loaded from disk.");
                }
                
                cachedImage = [UIImage imageWithData:imageData];
            }
        } else {
            if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2) {
                NSLog(@"Loaded from memory.");
            }
            
        }
    }
    
    return cachedImage;
}

#pragma mark - Image Cache Flush

- (void)flushMemoryStorage {
    [self.memoryStorage removeAllObjects];
}

- (void)clearMemoryStorageForURL:(NSString *)imageURL {
    NSArray *urlKeys = [self.memoryStorage allKeys];
    
    if ([urlKeys count] == 0) {
        return;
    }
    
    for (NSString *urlKey in urlKeys) {
        NSRange urlPrefixRange = [urlKey rangeOfString:imageURL];
        
        if ([self.memoryStorage count] == 0) {
            break;
        }
        
        switch (urlPrefixRange.location) {
            case 0: {
                [self.memoryStorage removeObjectForKey:urlKey];
            }
                break;
                
            default:
                break;
        }
    }
}

@end
