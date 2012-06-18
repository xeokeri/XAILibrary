//
//  XAIImageCacheDefines.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

/** NSUInteger */
#define kXAIImageCacheQueueMaxLimit     10
#define kXAIImageCacheFlushInterval     7 /** Number in days. */

/** CGFloat */
#define kXAIImageCacheTimeoutInterval   15.0f
#define kXAIImageCacheFadeInDuration    0.25f

/** NSString */
#define kXAIImageCacheFlushPerformed    @"ImageCacheFlushLastPerformed"
#define kXAIImageCacheDirectoryPath     @"ImageCache"
#define kXAIImageCacheFileNamePath      @"%@/%@.png"

/** BOOL */
#define kXAIImageCacheSliceDebugging    YES
