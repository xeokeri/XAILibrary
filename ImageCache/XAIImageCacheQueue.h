//
//  XAIImageCacheQueue.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAIImageCacheQueue : NSOperationQueue

@property (nonatomic, strong, readonly) NSMutableArray *urlList;

+ (XAIImageCacheQueue *)sharedQueue;

- (void)removeURL:(NSString *)url;
- (void)cancelOperationForURL:(NSString *)url;

@end
