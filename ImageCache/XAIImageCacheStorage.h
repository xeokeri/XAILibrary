//
//  XAIImageCacheStorage.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/15/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, XAIImageCacheStorageFlushInterval) {
    XAIImageCacheStorageFlushIntervalDay         = 1,
    XAIImageCacheStorageFlushIntervalWeek        = 7,
    XAIImageCacheStorageFlushIntervalMonth       = 30,
    XAIImageCacheStorageFlushIntervalYearQuarter = (XAIImageCacheStorageFlushIntervalMonth * 3), /** 90 */
    XAIImageCacheStorageFlushIntervalYearHalf    = (XAIImageCacheStorageFlushIntervalYearQuarter * 2), /** 180 */
    XAIImageCacheStorageFlushIntervalYearFull    = 365
};

@interface XAIImageCacheStorage : NSObject {
    @protected
    XAIImageCacheStorageFlushInterval cacheIntervalNumberOfDays;
    
    @private
    NSCache *cacheStorage;
}

@property (nonatomic) XAIImageCacheStorageFlushInterval cacheIntervalNumberOfDays;

+ (XAIImageCacheStorage *)sharedStorage;

#pragma mark - NSURL - File Path

- (NSURL *)filePathWithImageURL:(NSString *)imageURL temporary:(BOOL)tempStorage;

#pragma mark - Image Load

- (UIImage *)cachedImageForURL:(NSString *)imageURL;
- (UIImage *)cachedImageForURL:(NSString *)imageURL temporary:(BOOL)tempStorage;

#pragma mark - Image - Last Modified Date

- (NSDate *)lastModifiedDateForURL:(NSString *)imageURL temporary:(BOOL)tempStorage;

#pragma mark - Image Save

- (BOOL)saveImage:(UIImage *)image forURL:(NSString *)imageURL;
- (BOOL)saveImage:(UIImage *)image forURL:(NSString *)imageURL temporary:(BOOL)tempStorage;
- (BOOL)saveImage:(UIImage *)image forURL:(NSString *)imageURL temporary:(BOOL)tempStorage requireJPEG:(BOOL)jpegOnly;

#pragma mark - Image Delete

- (void)cacheCleanup;
- (BOOL)flushTemporaryStorage;
- (BOOL)deleteImageWithURL:(NSString *)imageURL temporary:(BOOL)tempStorage;

#pragma mark - Image Memory Flush All

- (void)flushMemoryStorage;

#pragma mark - Image Memory Flush Single

- (void)clearMemoryStorageForURL:(NSString *)imageURL;

@end
