//
//  XAIImageCacheQueue.m
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheDefines.h"

#import "XAIImageCacheOperation.h"

#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@implementation XAIImageCacheQueue

@synthesize urlList;

- (id)init {
    self = [super init];
    
    if (self) {
        self.maxConcurrentOperationCount = kXAIImageCacheQueueMaxLimit;
        self.urlList                     = [NSMutableArray array];
    }
    
    return self;
}

+ (XAIImageCacheQueue *)sharedQueue {
    static XAIImageCacheQueue *instanceQueue;
    
    @synchronized(self) {
        if (!instanceQueue) {
            NSAssert(instanceQueue == nil, @"InstanceQueue should be nil.");
            
            instanceQueue = [[self alloc] init];
        }
    }
    
    NSAssert(instanceQueue, @"InstanceQueue should not be nil.");
    
    return instanceQueue;
}

- (void)cacheCleanup {
    NSUserDefaults *defaults       = [NSUserDefaults standardUserDefaults];
    NSDate *currentDate            = [NSDate date];
    NSDate *lastUpdatedDate        = [defaults objectForKey:kXAIImageCacheFlushPerformed];
    NSUInteger updateTimeframe     = (60 * 60 * 24 * kXAIImageCacheFlushInterval); // seconds, minutes, hours, days...
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
        NSString *cacheFolder      = [[cachePaths lastObject] stringByAppendingPathComponent:kXAIImageCacheDirectoryPath];
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
                        [error logDetailsFailedOnSelector:_cmd line:__LINE__];
                        
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

- (void)addOperation:(NSOperation *)op {
    @synchronized(self) {
        if ([op isKindOfClass:[XAIImageCacheOperation class]]) {
            NSString *operationURL = ((XAIImageCacheOperation *)op).downloadURL;
            
            if (operationURL.length > 0) {
                @try {
                    if  (![self.urlList containsObject:operationURL]) {
                        if (op) {
                            [self.urlList addObject:operationURL];
                            [super addOperation:op];
                        }
                    }
                } @catch (NSException *exception) {
                    [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
                }
            }
        }
    }
}

- (void)removeURL:(NSString *)url {
    @synchronized(self) {
        @try {
            if ([self.urlList containsObject:url]) {
                [self.urlList removeObject:url];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    }
}

@end
