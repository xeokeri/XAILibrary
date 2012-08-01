//
//  XAIImageCacheStorage.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAIImageCacheStorage : NSObject {
    @private
    NSMutableDictionary *memoryStorage;
}

@property (nonatomic, strong) NSMutableDictionary *memoryStorage;

+ (XAIImageCacheStorage *)sharedStorage;

- (UIImage *)cachedImageForURL:(NSString *)imageURL;

- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL;
- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL inMemory:(BOOL)inMemory;

- (void)flushMemoryStorage;
- (void)clearMemoryStorageForURL:(NSString *)imageURL;

@end
