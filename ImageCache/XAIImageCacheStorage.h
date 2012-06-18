//
//  XAIImageCacheStorage.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/15/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAIImageCacheStorage : NSObject

+ (XAIImageCacheStorage *)sharedStorage;

- (void)saveImage:(UIImage *)image forURL:(NSString *)imageURL;

@end
