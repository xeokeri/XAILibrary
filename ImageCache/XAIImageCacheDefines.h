//
//  XAIImageCacheDefines.h
//  XAIImageCache
//
//  Created by Xeon Xai on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

/** NSUInteger */
#define kXAIImageCacheQueueMaxLimit   10
#define kXAIImageCacheTimeoutInterval 10.0
#define kXAIImageCacheFlushInterval   7 /** Number in days. */

/** CGFloat */
#define kXAIImageCacheFadeInDuration  0.25f

/** NSString */
#define kXAIImageCacheFlushPerformed  @"ImageCacheFlushLastPerformed"
#define kXAIImageCacheDirectoryPath   @"ImageCache"
#define kXAIImageCacheFileNamePath    @"%@/%@.png"
