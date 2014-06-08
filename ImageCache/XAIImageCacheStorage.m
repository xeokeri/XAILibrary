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

- (NSString *)imagePathWithURL:(NSString *)imageURL temporary:(BOOL)tempStorage;
- (NSString *)filteredCachePathForTemporaryStorage:(BOOL)tempStorage;
- (BOOL)deleteImageForFilePath:(NSString *)filePath;

@end

@implementation XAIImageCacheStorage

@synthesize cacheStorage;
@synthesize cacheIntervalNumberOfDays;

#pragma mark - Init XAIImageCache

- (instancetype)init {
    self = [super init];
    
    if (self) {
        /** Configure the cache interval for flushing the temporary cache. */
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
        NSNumber *cacheStateTemp   = [[NSNumber alloc] initWithBool:YES];
        NSNumber *cacheStatePerm   = [[NSNumber alloc] initWithBool:NO];
        NSArray *cacheStates       = @[cacheStateTemp, cacheStatePerm];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        for (NSNumber *cacheState in cacheStates) {
            NSString *cacheFolder = [instanceStorage filteredCachePathForTemporaryStorage:[cacheState boolValue]];
            
            if (![fileManager fileExistsAtPath:cacheFolder]) {
                NSError *createDirError = nil;
                
                // Create the image cache storage folder.
                [fileManager createDirectoryAtPath:cacheFolder withIntermediateDirectories:NO attributes:nil error:&createDirError];
                
                // Debug logging.
                if (createDirError != nil) {
                    [createDirError logDetailsFailedOnSelector:_cmd line:__LINE__];
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

- (NSURL *)filePathWithImageURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    NSString *imagePath = [self imagePathWithURL:imageURL temporary:tempStorage];
    
    return [[NSURL alloc] initFileURLWithPath:imagePath isDirectory:NO];
}

#pragma mark - NSString - Image Path

- (NSString *)imagePathWithURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
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
    BOOL loggingEnabled  = ((kXAIImageCacheDebuggingMode == YES) && kXAIImageCacheDebuggingLevel >= 2);
    
    @try {
        cachedImage = [self.cacheStorage objectForKey:imageURL];
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    } @finally {
        if (cachedImage != nil) {
            /** Debug logging. */
            if (loggingEnabled) {
                NSLog(@"Loaded from memory cache for URL: %@", imageURL);
                
                return cachedImage;
            }
        } else {
            /** Debug logging. */
            if (loggingEnabled) {
                NSLog(@"Checking disk for URL: %@", imageURL);
            }
            
            /** Loading from disk. */
            NSError *imageLoadError = nil;
            NSString *imagePath     = [self imagePathWithURL:imageURL temporary:tempStorage];
            NSData *imageData       = [[NSData alloc] initWithContentsOfFile:imagePath options:NSDataReadingUncached error:&imageLoadError];
            
            if (imageLoadError != nil) {
                /** Debug logging. */
                if (loggingEnabled) {
                    NSLog(@"Error loading file from disk for URL: %@", imageURL);
                }
            } else {
                UIImage *imageFromData = [[UIImage alloc] initWithData:imageData];
                
                /** Update the cached image. */
                cachedImage = imageFromData;
                
                #if !__has_feature(objc_arc)
                    [imageFromData release];
                #endif
            }
            
            #if !__has_feature(objc_arc)
                [imageData release];
            #endif
            
            /** Image is loaded, add the file attributes. */
            if (cachedImage != nil) {
                /** Debug logging. */
                if (loggingEnabled) {
                    NSLog(@"Loaded from disk for URL: %@", imageURL);
                }
                
                /** Track any errors for updating the last modified date. */
                NSError *attributeError  = nil;
                
                /** Retreive the file attributes. */
                NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:imagePath error:&attributeError];
                
                /** Make the attributes writable. */
                NSMutableDictionary *modifiedAttributes = [[NSMutableDictionary alloc] initWithDictionary:attributes copyItems:YES];
                
                /** Set the last modified date timestamp to the current date timestamp. */
                modifiedAttributes[NSFileModificationDate] = [NSDate date];
                
                /** Save the file attributes for the image path. */
                [[NSFileManager defaultManager] setAttributes:modifiedAttributes ofItemAtPath:imagePath error:&attributeError];
                
                #if !__has_feature(objc_arc)
                    [modifiedAttributes release];
                #endif
                
                /** Debug logging. */
                if (attributeError != nil && loggingEnabled) {
                    [attributeError logDetailsFailedOnSelector:_cmd line:__LINE__];
                }
            }
        }
    }
    
    if ((cachedImage == nil) && loggingEnabled) {
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
    BOOL didImageSave   = NO;
    BOOL loggingEnabled = ((kXAIImageCacheDebuggingMode == YES) && kXAIImageCacheDebuggingLevel >= 2);
    
    // Check to see if there is image contents to be saved.
    if (image == nil) {
        return didImageSave;
    }
    
    // Add the image to the cache.
    [self.cacheStorage setObject:image forKey:imageURL];
    
    @autoreleasepool {
        // File path to save the contents of the image.
        NSString *filePath  = [self imagePathWithURL:imageURL temporary:tempStorage];
        
        // Data from image contents, to be saved to the file system.
        NSData *imageData   = ((kXAIImageCacheTempAsPNG == YES) && (tempStorage == YES))
            ? UIImagePNGRepresentation(image)
            : ((tempStorage == YES || jpegOnly == YES)
               ? UIImageJPEGRepresentation(image, 1.0f)
               : UIImagePNGRepresentation(image));
        
        // Monitor any write access errors.
        NSError *writeError = nil;
        
        // Writing options, based on storage state.
        NSDataWritingOptions writeOptions = (tempStorage) ? NSDataWritingFileProtectionNone : NSDataWritingAtomic;
        
        // Check to see if the image contents was saved.
        didImageSave = [imageData writeToFile:filePath options:writeOptions error:&writeError];
        
        // Debugging.
        if ((!didImageSave || writeError != nil) && loggingEnabled) {
            NSLog(@"Failed to save image to disk for path: %@", [self imagePathWithURL:imageURL temporary:tempStorage]);
            
            if (writeError != nil) {
                NSLog(@"Error writing file: %@", [writeError localizedDescription]);
            }
        }
    }
    
    return didImageSave;
}

#pragma mark - Image - Delete

- (BOOL)flushTemporaryStorage {
    BOOL successful     = YES;
    BOOL loggingEnabled = ((kXAIImageCacheDebuggingMode == YES) && kXAIImageCacheDebuggingLevel >= 2);
    
    @try {
        NSError *dirReadError      = nil;
        NSString *cacheFolder      = [self filteredCachePathForTemporaryStorage:YES];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSArray *cacheFiles        = [fileManager contentsOfDirectoryAtPath:cacheFolder error:&dirReadError];
        
        if (dirReadError != nil) {
            [dirReadError logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            for (NSString *aCachedFile in cacheFiles) {
                NSString *fileDir  = [[NSString alloc] initWithString:cacheFolder];
                NSString *filePath = [fileDir stringByAppendingPathComponent:aCachedFile];
                BOOL fileExists    = [fileManager fileExistsAtPath:filePath];
                BOOL isDeletable   = [fileManager isDeletableFileAtPath:filePath];
                
                #if !__has_feature(objc_arc)
                    [fileDir release];
                #endif
                
                if (fileExists && isDeletable) {
                    [self deleteImageForFilePath:filePath];
                    /** Monitor any file access errors. */
                    NSError *removeError = nil;
                    
                    /** Remove the old file from the cache. */
                    BOOL didRemoveFile   = [fileManager removeItemAtPath:filePath error:&removeError];
                    
                    if (!didRemoveFile) {
                        if (loggingEnabled) {
                            NSLog(@"Image not removed for file path: %@", filePath);
                        }
                        
                        successful = NO;
                    }
                    
                    if ((removeError != nil) && loggingEnabled) {
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

- (void)cacheCleanup {
    NSUserDefaults *defaults       = [NSUserDefaults standardUserDefaults];
    NSDate *currentDate            = [[NSDate alloc] init];
    NSDate *updatedDate            = [defaults objectForKey:kXAIImageCacheFlushPerformed];
    NSNumber *numberOfDays         = [[NSNumber alloc] initWithUnsignedInteger:self.cacheIntervalNumberOfDays];
    CGFloat updateTimeframe        = (60.0f * 60.0f * 24.0f * [numberOfDays doubleValue]); // seconds, minutes, hours, days...
    NSTimeInterval currentInterval = [currentDate timeIntervalSinceNow];
    BOOL isFlushRequired           = NO;
    
    // Check to see if a cache flush has previously been performed, otherwise set the default date.
    if (updatedDate == nil) {
        [defaults setObject:currentDate forKey:kXAIImageCacheFlushPerformed];
    } else {
        NSTimeInterval
            lastFlushInterval = [updatedDate timeIntervalSinceNow],
            diffFlushInterval = (currentInterval - lastFlushInterval);
        
        if (diffFlushInterval > updateTimeframe) {
            isFlushRequired = YES;
        }
    }
    
    #if !__has_feature(objc_arc)
        [currentDate release];
        [numberOfDays release];
    #endif
    
    if (!isFlushRequired) {
        return;
    }
    
    @try {
        NSError *dirReadError      = nil;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *cacheFolder      = [self filteredCachePathForTemporaryStorage:YES];
        NSArray *cachedFiles       = [fileManager contentsOfDirectoryAtPath:cacheFolder error:&dirReadError];
        
        // Check directory read access.
        if (dirReadError != nil) {
            [dirReadError logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            for (NSString *aCachedFile in cachedFiles) {
                NSString *fileDir  = [[NSString alloc] initWithString:cacheFolder];
                NSString *filePath = [fileDir stringByAppendingPathComponent:aCachedFile];
                BOOL fileExists    = [fileManager fileExistsAtPath:filePath];
                BOOL isDeletable   = [fileManager isDeletableFileAtPath:filePath];
                
                #if !__has_feature(objc_arc)
                    [fileDir release];
                #endif
                
                if (fileExists && isDeletable) {
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
                        [self deleteImageForFilePath:filePath];
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

- (BOOL)deleteImageForFilePath:(NSString *)filePath {
    /**  Logging state. */
    BOOL loggingEnabled = ((kXAIImageCacheDebuggingMode == YES) && kXAIImageCacheDebuggingLevel >= 2);
    
    /** Monitor any file access errors. */
    NSError *removeError = nil;
    
    /** File manager. */
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    /** Remove the old file from the cache. */
    BOOL didRemoveFile = [fileManager removeItemAtPath:filePath error:&removeError];
    
    if (!didRemoveFile && loggingEnabled) {
        NSLog(@"Image not removed for file path: %@", filePath);
    }
    
    if ((removeError != nil) && loggingEnabled) {
        [removeError logDetailsFailedOnSelector:_cmd line:__LINE__];
    }
    
    return didRemoveFile;
}

- (void)deleteImageForURL:(NSString *)imageURL temporary:(BOOL)tempStorage {
    // Logging state.
    BOOL loggingEnabled = ((kXAIImageCacheDebuggingMode == YES) && kXAIImageCacheDebuggingLevel >= 2);
    
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    NSError *writeError                = nil;
    
    // Local file URL to delete.
    NSURL *fileURL = [self filePathWithImageURL:imageURL temporary:tempStorage];
    
    // Use the file coordinator to ensure the file can be written and deleted.
    [fileCoordinator coordinateWritingItemAtURL:fileURL options:NSFileCoordinatorWritingForDeleting error:&writeError byAccessor:^(NSURL *filteredDeleteURL) {
        if (writeError != nil) {
            [writeError logDetailsFailedOnSelector:_cmd line:__LINE__];
        } else {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSError *deleteError       = nil;
            
            // Remove the file from the cache.
            BOOL didRemoveFile = [fileManager removeItemAtURL:filteredDeleteURL error:&deleteError];
            
            if (!didRemoveFile && loggingEnabled) {
                NSLog(@"Image not removed for URL: %@", fileURL);
            }
            
            // Log any errors.
            if ((deleteError != nil) && loggingEnabled) {
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
