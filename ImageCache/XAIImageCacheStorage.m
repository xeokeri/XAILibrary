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

/** XAIUtility Categories */
#import "NSString+XAIUtilities.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@interface XAIImageCacheStorage()

@property (nonatomic, strong) NSCache *cacheStorage;

- (NSString *)imagePathForURL:(NSString *)imageURL temporary:(BOOL)tempStorage;
- (NSString *)filteredCachePathForTemporaryStorage:(BOOL)tempStorage;

@end

@implementation XAIImageCacheStorage

@synthesize cacheStorage;
@synthesize cacheIntervalNumberOfDays;

#pragma mark - Init XAIImageCache

- (instancetype)init {
    self = [super init];
    
    if (self) {
        /** Set the default number of days for the cache cleanup. */
        self.cacheIntervalNumberOfDays = kXAIImageCacheFlushInterval;
        
        /** Set the cache storage. */
        NSCache *memoryCache = [[NSCache alloc] init];
        
        self.cacheStorage = memoryCache;
        
        #if !__has_feature(objc_arc)
            [memoryCache release];
        #endif
    }
    
    return self;
}

+ (XAIImageCacheStorage *)sharedStorage {
    static XAIImageCacheStorage *instanceStorage = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        #ifdef DEBUG
            NSAssert(instanceStorage == nil, @"InstanceStorage should be nil.");
        #endif
        
        instanceStorage = [[self alloc] init];
        
        /** Create the image cache folders. */
        NSError *error             = nil;
        NSNumber *cacheStateTemp   = [[NSNumber alloc] initWithBool:YES];
        NSNumber *cacheStatePerm   = [[NSNumber alloc] initWithBool:NO];
        NSArray *cacheStates       = @[cacheStateTemp, cacheStatePerm];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        for (NSNumber *cacheState in cacheStates) {
            NSString *cacheFolder = [instanceStorage filteredCachePathForTemporaryStorage:[cacheState boolValue]];
            
            if (![fileManager fileExistsAtPath:cacheFolder]) {
                [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:&error];
                
                if (error != nil) {
                    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            }
        }
        
        #if !__has_feature(objc_arc)
            [cacheStateTemp release];
            [cacheStatePerm release];
        #endif
        
        #ifdef DEBUG
            NSAssert(instanceStorage, @"'instanceStorage' should not be nil.");
            NSAssert([instanceStorage isKindOfClass:[XAIImageCacheStorage class]], @"'instanceStorage' is not an instance of XAIImageCacheStorage class.");
            NSAssert((instanceStorage.cacheStorage != nil), @"'cacheStorage' is nil.");
        #endif
    });
    
    return instanceStorage;
}

#pragma mark - NSURL - File Path

- (NSURL *)filePathForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    NSString *imagePath = [self imagePathForURL:imageURL temporary:tempStorage];
    
    return [[NSURL alloc] initFileURLWithPath:imagePath isDirectory:NO];
}

#pragma mark - NSString - Image Path

- (NSString *)imagePathForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    NSString
        *encodedName  = [imageURL md5HexEncode],
        *imagePathExt = [imageURL pathExtension],
        *imagePath    = [[self filteredCachePathForTemporaryStorage:tempStorage] stringByAppendingPathComponent:encodedName];
    
    if ([imagePathExt length] > 0) {
        imagePath = [imagePath stringByAppendingPathExtension:imagePathExt];
    }
    
    return imagePath;
}

- (NSString *)filteredCachePathForTemporaryStorage:(BOOL)tempStorage {
    NSSearchPathDirectory searchPathDir = (tempStorage) ? NSCachesDirectory : NSDocumentDirectory;
    NSArray  *filteredCachePaths        = NSSearchPathForDirectoriesInDomains(searchPathDir, NSUserDomainMask, YES);
    NSString *storageCachePathPrefix    = (NSString *) [filteredCachePaths lastObject];
    NSString *storageCachePathComponent = (tempStorage == YES) ? kXAIImageCacheDirectoryPathTemp : kXAIImageCacheDirectoryPathPerm;
    
    return [storageCachePathPrefix stringByAppendingPathComponent:storageCachePathComponent];
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
            
            cachedImage = [[UIImage alloc] initWithData:imageContents];
            
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
                modifiedAttributes[NSFileModificationDate] = [NSDate date];
                
                /** Save the file attributes for the image path. */
                [[NSFileManager defaultManager] setAttributes:modifiedAttributes ofItemAtPath:imagePath error:&error];
                
                if (error != nil) {
                    [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            }
            
            #if !__has_feature(objc_arc)
                [cachedImage release];
            #endif
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
    
    // Check to see if there is image contents to be saved.
    if (image == nil) {
        return didImageSave;
    }
    
    // Add the image to the cache.
    [self.cacheStorage setObject:image forKey:imageURL];
    
    @autoreleasepool {
        NSData *imageData   = ((kXAIImageCacheTempAsPNG == YES) && (tempStorage == YES))
            ? UIImagePNGRepresentation(image)
            : ((tempStorage == YES || jpegOnly == YES) ? UIImageJPEGRepresentation(image, 1.0f) : UIImagePNGRepresentation(image));
        NSData *contentData = [[NSData alloc] initWithData:imageData];
        NSString *imagePath = [self imagePathForURL:imageURL temporary:tempStorage];
        
        // Check to see if the image contents was saved.
        didImageSave = [contentData writeToFile:imagePath atomically:!tempStorage];
        
        // Debugging.
        if (!didImageSave && kXAIImageCacheDebuggingMode) {
            NSLog(@"Failed to save image to disk for path: %@", imagePath);
        }
        
        #if !__has_feature(objc_arc)
            [contentData release];
        #endif
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
        NSString *cacheFolder      = [self filteredCachePathForTemporaryStorage:YES];
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
                    NSDate *lastModified = fileAttributes[NSFileModificationDate];
                    
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
        NSString *cacheFolder      = [self filteredCachePathForTemporaryStorage:YES];
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
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    NSError *writeError                = nil;
    
    // Local file URL to delete.
    NSURL *fileURL = [self filePathForURL:imageURL temporary:tempStorage];
    
    // Use the file coordinator to ensure the file can be written and deleted.
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:&writeError byAccessor:^(NSURL *filteredDeleteURL) {
        if (writeError != nil) {
            [writeError logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *deleteError       = nil;
            
            // Remove the file.
            [fileManager removeItemAtURL:filteredDeleteURL error:&deleteError];
            
            // Log any errors.
            if (deleteError != nil) {
                [deleteError logDetailsFailedOnSelector:_cmd line:__LINE__];
            }
        }
    }];
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
