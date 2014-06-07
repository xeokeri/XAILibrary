//
//  XAIImageCacheDefines.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

/** BOOL */
#ifndef kXAIImageCacheTempAsPNG
    #define kXAIImageCacheTempAsPNG         NO
#endif

/** NSUInteger */
#define kXAIImageCacheQueueMaxLimit         10
#define kXAIImageCacheFlushInterval         7 /** Number in days. */

/** CGFloat */
#define kXAIImageCacheTimeoutInterval       15.0f
#define kXAIImageCacheFadeInDuration        0.25f
#define kXAIImageCacheCropEdgeOverflow      2.0f

/** NSString */
#define kXAIImageCacheFlushPerformed        @"ImageCacheFlushLastPerformed"
#define kXAIImageCacheDirectoryPathTemp     @"ImageCache"
#define kXAIImageCacheDirectoryPathPerm     @"ImageStorage"

/** Debugging */
#define kXAIImageCacheDebuggingMode         NO
#define kXAIImageCacheDebuggingLevel        0
