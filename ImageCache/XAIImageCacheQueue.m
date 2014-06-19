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

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@implementation XAIImageCacheQueue

@synthesize urlList;

- (id)init {
    self = [super init];
    
    if (self) {
        self->urlList = [NSMutableArray array];
    }
    
    return self;
}

+ (XAIImageCacheQueue *)sharedQueue {
    static XAIImageCacheQueue *instanceQueue;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        #ifndef DEBUG
            NSAssert(instanceQueue == nil, @"InstanceQueue should be nil.");
        #endif
        
        instanceQueue = [[self alloc] init];
    });
    
    #ifndef DEBUG
        NSAssert(instanceQueue, @"InstanceQueue should not be nil.");
    #endif
    
    return instanceQueue;
}

- (void)addOperation:(NSOperation *)op {
    // Check to see if [super addOperation:op] should be called.
    if ([op isKindOfClass:[XAIImageCacheOperation class]]) {
        NSString *operationURL = ((XAIImageCacheOperation *)op).downloadURL;
        
        if (operationURL.length > 0) {
            BOOL shouldAddOperation = NO;
            
            @try {
                if  (![self.urlList containsObject:operationURL]) {
                    if (op) {
                        shouldAddOperation = YES;
                    }
                } else {
                    for (NSOperation *pendingOp in [self operations]) {
                        if ([pendingOp isCancelled] && [pendingOp isKindOfClass:[XAIImageCacheOperation class]]) {
                            NSString *pendingURL = ((XAIImageCacheOperation *)op).downloadURL;
                            
                            if (pendingOp && [pendingURL isEqualToString:operationURL]) {
                                shouldAddOperation = YES;
                            }
                        }
                    }
                }
            } @catch (NSException *exception) {
                [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
            } @finally {
                // Check to see if the operation should successfully be added.
                if (shouldAddOperation) {
                    [self.urlList addObject:operationURL];
                    
                    // Operation can be added.
                    [super addOperation:op];
                }
            }
        }
    }
}

- (void)removeURL:(NSString *)url {
    @synchronized(self) {
        @try {
            if ([self->urlList containsObject:url]) {
                [self->urlList removeObject:url];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    }
}

- (void)cancelOperationForURL:(NSString *)url {
    @try {
        for (NSOperation *op in self.operations) {
            if ([op isKindOfClass:[XAIImageCacheOperation class]]) {
                NSString *operationURL = ((XAIImageCacheOperation *)op).downloadURL;
                
                if ([operationURL isEqualToString:url]) {
                    [op cancel];
                    
                    [self removeURL:url];
                }
            }
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    }
}

- (void)cancelAllOperations {
    /** Set all the delegate views to nil. */
    for (NSOperation *op in [self operations]) {
        if ([op isKindOfClass:[XAIImageCacheOperation class]]) {
            [((XAIImageCacheOperation *) op) setDelegateView:nil];
        }
    }
    
    [super cancelAllOperations];
}

@end
