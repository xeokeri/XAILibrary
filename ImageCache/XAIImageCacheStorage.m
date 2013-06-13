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

@interface XAIImageCacheStorage()

@property (nonatomic, strong) NSCache *cacheStorage;

- (NSString *)imagePathForURL:(NSString *)imageURL temporary:(BOOL)tempStorage;

@end

@implementation XAIImageCacheStorage

@synthesize cacheStorage;
@synthesize cacheIntervalNumberOfDays;

#pragma mark - Init XAIImageCache

- (id)init {
    self = [super init];
    
    if (self) {
        /** Set the default number of days for the cache cleanup. */
        self.cacheIntervalNumberOfDays = kXAIImageCacheFlushInterval;
        
        /** Set the cache storage. */
        NSCache *memoryCache = [[NSCache alloc] init];
        
        self.cacheStorage  = memoryCache;
        
        #if !__has_feature(objc_arc)
            [memoryCache release];
        #endif
    }
    
    return self;
}

+ (XAIImageCacheStorage *)sharedStorage {
    static XAIImageCacheStorage *instanceStorage = nil;
    
    if (instanceStorage != nil) {
        return instanceStorage;
    }
    
    @synchronized(self) {
        if (!instanceStorage) {
            NSAssert(instanceStorage == nil, @"InstanceStorage should be nil.");
            
            instanceStorage = [[self alloc] init];
            
            /** Create the image cache folder. */
            NSError *error             = nil;
            NSArray *cachePaths        = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            NSArray *cacheDirectories  = [NSArray arrayWithObjects:kXAIImageCacheDirectoryPathTemp, kXAIImageCacheDirectoryPathPerm, nil];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            
            for (NSString *directory in cacheDirectories) {
                NSString *cacheFolder = [[cachePaths lastObject] stringByAppendingPathComponent:directory];
                
                if (![fileManager fileExistsAtPath:cacheFolder]) {
                    [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:&error];
                    
                    if (error != nil) {
                        [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                    }
                }
            }
        }
        
        NSAssert(instanceStorage, @"'instanceStorage' should not be nil.");
        NSAssert([instanceStorage isKindOfClass:[XAIImageCacheStorage class]], @"'instanceStorage' is not an instance of XAIImageCacheStorage class.");
        NSAssert((instanceStorage.cacheStorage != nil), @"'cacheStorage' is nil.");
    }
    
    return instanceStorage;
}

#pragma mark - NSURL - File Path

+ (NSURL *)filePathForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    NSString *imagePath = [[self sharedStorage] imagePathForURL:imageURL temporary:tempStorage];
    
    return [NSURL fileURLWithPath:imagePath];
}

#pragma mark - NSString - Image Path

- (NSString *)imagePathForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    NSString *storageDirectory = (tempStorage == YES) ? kXAIImageCacheDirectoryPathTemp : kXAIImageCacheDirectoryPathPerm;
    NSArray *cachePath         = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *imagePath        = [[cachePath lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, storageDirectory, [imageURL md5HexEncode]]];
    
    return imagePath;
}

#pragma mark - Image - Load

- (UIImage *)cachedImageForURL:(NSString *)imageURL {
    return [self cachedImageForURL:imageURL temporary:YES];
}

- (UIImage *)cachedImageForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    UIImage *cachedImage = nil;
    
    @try {
        cachedImage = [self.cacheStorage objectForKey:imageURL];
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    } @finally {
        if (cachedImage == nil) {
            /** Loading from disk. */
            if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2) {
                NSLog(@"Checking disk.");
            }
            
            NSString *imagePath   = [self imagePathForURL:imageURL temporary:tempStorage];
            NSData *imageContents = [NSData dataWithContentsOfFile:imagePath];
            
            cachedImage = [UIImage imageWithData:imageContents];
            
            if (cachedImage != nil) {
                if (kXAIImageCacheDebuggingMode && (kXAIImageCacheDebuggingLevel >= 2)) {
                    NSLog(@"Loaded from disk.");
                }
                
                /** Track any errors for updating the last modified date. */
                NSError *error = nil;
                
                /** Retreive the file attributes. */
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:imagePath error:&error];
                
                /** Make the attributes writable. */
                NSMutableDictionary *modifiedAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
                
                /** Set the last modified date timestamp to the current date timestamp. */
                [modifiedAttributes setObject:[NSDate date] forKey:NSFileModificationDate];
                
                /** Save the file attributes for the image path. */
                [[NSFileManager defaultManager] setAttributes:modifiedAttributes ofItemAtPath:imagePath error:&error];
                
                if (error != nil) {
                    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            }
        } else {
            if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2) {
                NSLog(@"Loaded from memory.");
            }
            
        }
    }
    
    if ((cachedImage == nil) && (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2)) {
        NSLog(@"Image not loaded for URL: %@", imageURL);
    }
    
    return cachedImage;
}

#pragma mark - Image - Save

- (BOOL)saveImage:(UIImage *)image forURL:(NSString *)imageURL {
    return [self saveImage:image forURL:imageURL temporary:YES];
}

- (BOOL)saveImage:(UIImage *)image forURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    return [self saveImage:image forURL:imageURL temporary:tempStorage requireJPEG:NO];
}

- (BOOL)saveImage:(UIImage *)image forURL:(NSString *)imageURL temporary:(BOOL)tempStorage requireJPEG:(BOOL)jpegOnly {
    BOOL didImageSave = NO;
    
    if (image == nil) {
        return didImageSave;
    }
    
    // Add the image to the cache.
    [self.cacheStorage setObject:image forKey:imageURL];
    
    @autoreleasepool {
        NSData
            *imageData   = ((kXAIImageCacheTempAsPNG == YES) && (tempStorage == YES))
                ? UIImagePNGRepresentation(image)
                : ((tempStorage == YES || jpegOnly == YES) ? UIImageJPEGRepresentation(image, 1.0f) : UIImagePNGRepresentation(image)),
            *contentData = [NSData dataWithData:imageData];
        
        NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        
        NSString
            *storagePath    = (tempStorage == YES) ? kXAIImageCacheDirectoryPathTemp : kXAIImageCacheDirectoryPathPerm,
            *imagePath      = [[cachePaths lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, storagePath, [imageURL md5HexEncode]]];
        
        didImageSave = [contentData writeToFile:imagePath atomically:!tempStorage];
        
        if (!didImageSave && kXAIImageCacheDebuggingMode) {
            NSLog(@"Failed to save image to disk for path: %@", imagePath);
        }
    }
    
    return didImageSave;
}

#pragma mark - Image - Delete

- (void)cacheCleanup {
    NSUserDefaults *defaults       = [NSUserDefaults standardUserDefaults];
    NSDate *currentDate            = [NSDate date];
    NSDate *lastUpdatedDate        = [defaults objectForKey:kXAIImageCacheFlushPerformed];
    NSUInteger updateTimeframe     = (60 * 60 * 24 * self.cacheIntervalNumberOfDays); // seconds, minutes, hours, days...
    NSTimeInterval currentInterval = [currentDate timeIntervalSinceNow];
    
    BOOL isFlushRequired = NO;
    
    if (lastUpdatedDate == nil) {
        isFlushRequired = NO;
        
        [defaults setObject:currentDate forKey:kXAIImageCacheFlushPerformed];
    } else {
        NSTimeInterval lastFlushInterval = [lastUpdatedDate timeIntervalSinceNow];
        
        if ((currentInterval - lastFlushInterval) > updateTimeframe) {
            isFlushRequired = YES;
        }
    }
    
    if (!isFlushRequired) {
        return;
    }
    
    @try {
        NSError *error             = nil;
        NSArray *cachePaths        = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheFolder      = [[cachePaths lastObject] stringByAppendingPathComponent:kXAIImageCacheDirectoryPathTemp];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *cacheFiles        = [fileManager contentsOfDirectoryAtPath:cacheFolder error:&error];
        
        if (error != nil) {
            [error logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            for (NSString *cachedFile in cacheFiles) {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", cacheFolder, cachedFile];
                BOOL isDirectory;
                
                if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory) {
                    NSError *fileError = nil;
                    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:filePath error:&fileError];
                    
                    if (fileError != nil) {
                        [fileError logDetailsFailedOnSelector:_cmd line:__LINE__];
                        
                        continue;
                    }
                    
                    /** File last modified date. */
                    NSDate *lastModified = [fileAttributes objectForKey:NSFileModificationDate];
                    
                    /** Time in seconds of last modified interval. */
                    NSTimeInterval lastModifiedInterval = [lastModified timeIntervalSinceNow];
                    
                    if ((currentInterval - lastModifiedInterval) > updateTimeframe) {
                        NSError *removeError = nil;
                        
                        /** Remove the old file from the cache. */
                        [fileManager removeItemAtPath:filePath error:&removeError];
                        
                        if (removeError != nil) {
                            [removeError logDetailsFailedOnSelector:_cmd line:__LINE__];
                        }
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    } @finally {
        [defaults setObject:[NSDate date] forKey:kXAIImageCacheFlushPerformed];
    }
}

- (BOOL)flushTemporaryStorage {
    BOOL successful = YES;
    
    @try {
        NSError *error             = nil;
        NSArray *cachePaths        = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        NSString *cacheFolder      = [[cachePaths lastObject] stringByAppendingPathComponent:kXAIImageCacheDirectoryPathTemp];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *cacheFiles        = [fileManager contentsOfDirectoryAtPath:cacheFolder error:&error];
        
        if (error != nil) {
            [error logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            for (NSString *cachedFile in cacheFiles) {
                NSString *filePath = [NSString stringWithFormat:@"%@/%@", cacheFolder, cachedFile];
                BOOL isDirectory;
                
                if (kXAIImageCacheDebuggingMode && kXAIImageCacheDebuggingLevel >= 2) {
                    NSLog(@"FilePath: %@", filePath);
                }
                
                if ([fileManager fileExistsAtPath:filePath isDirectory:&isDirectory] && !isDirectory) {
                    NSError *removeError = nil;
                    
                    BOOL removed = [fileManager removeItemAtPath:filePath error:&removeError];
                    
                    if (!removed) {
                        successful = NO;
                    }
                    
                    if (removeError != nil) {
                        [removeError logDetailsFailedOnSelector:_cmd line:__LINE__];
                    }
                }
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        
        successful = NO;
    }
    
    return successful;
}

- (void)deleteImageForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *cachePaths        = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSError *deleteError       = nil;
    
    NSString
        *storagePath = (tempStorage == YES) ? kXAIImageCacheDirectoryPathTemp : kXAIImageCacheDirectoryPathPerm,
        *imagePath   = [[cachePaths lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:kXAIImageCacheFileNamePath, storagePath, [imageURL md5HexEncode]]];
    
    if ([fileManager fileExistsAtPath:imagePath]) {
        [fileManager removeItemAtPath:imagePath error:&deleteError];
        
        if (deleteError != nil) {
            [deleteError logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    }
}

#pragma mark - Image - Memory Flush All

- (void)flushMemoryStorage {
    [self.cacheStorage removeAllObjects];
}

#pragma mark - Image - Memory Flush Single

- (void)clearMemoryStorageForURL:(NSString *)imageURL {
    [self.cacheStorage removeObjectForKey:imageURL];
}

@end
