//
//  XAIImageCacheDefines.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

/** BOOL */
#define XAIImageCacheTempAsPNG                      NO

/** CGFloat */
#define XAIImageCacheTimeoutInterval                15.0f
#define XAIImageCacheFadeInDuration                 0.25f
#define XAIImageCacheCropEdgeOverflow               2.0f

/** Debugging Levels */
typedef NS_ENUM(NSUInteger, XAIImageCacheDebuggingLevel) {
    XAIImageCacheDebuggingLevelDisabled = 0,
    XAIImageCacheDebuggingLevelLow,
    XAIImageCacheDebuggingLevelMedium,
    XAIImageCacheDebuggingLevelHigh,
};

/** Debugging State */
#ifndef DEBUG
    #define XAIImageCacheDebuggingLevelCurrentState XAIImageCacheDebuggingLevelDisabled
#else
    #define XAIImageCacheDebuggingLevelCurrentState XAIImageCacheDebuggingLevelMedium
#endif
