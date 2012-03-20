//
//  XAIImageCacheQueue.m
//  XAIImageCache
//
//  Created by Xeon Xai on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIImageCacheQueue.h"
#import "XAIImageCacheDefines.h"

#import "NSError+Customized.h"
#import "NSException+Customized.h"

@implementation XAIImageCacheQueue

- (id)init {
    self = [super init];
    
    if (self) {
        self.maxConcurrentOperationCount = kXAIImageCacheQueueMaxLimit;
    }
    
    return self;
}

+ (XAIImageCacheQueue *)sharedQueue {
    static XAIImageCacheQueue *instanceQueue;
    
    @synchronized(self) {
        if (!instanceQueue) {
            NSAssert(instanceQueue == nil, @"InstanceQueue should be nil.");
            
            instanceQueue = [[self alloc] init];
            
            //NSLog(@"InstanceQueue: %@", instanceQueue);
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
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__];
    } @finally {
        [defaults setObject:[NSDate date] forKey:kXAIImageCacheFlushPerformed];
    }
}

@end
