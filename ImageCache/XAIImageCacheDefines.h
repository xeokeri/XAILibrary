//
//  XAIImageCacheDefines.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

/** BOOL */
BOOL const XAIImageCacheTempAsPNG               = NO;

/** CGFloat */
CGFloat const XAIImageCacheTimeoutInterval      = 15.0f;
CGFloat const XAIImageCacheFadeInDuration       = 0.25f;
CGFloat const XAIImageCacheCropEdgeOverflow     = 2.0f;

/** Debugging Levels */
typedef NS_ENUM(NSUInteger, XAIImageCacheDebuggingLevel) {
    XAIImageCacheDebuggingLevelDisabled = 0,
    XAIImageCacheDebuggingLevelLow,
    XAIImageCacheDebuggingLevelMedium,
    XAIImageCacheDebuggingLevelHigh,
};

/** Debugging State */
XAIImageCacheDebuggingLevel const XAIImageCacheDebuggingLevelCurrentState = XAIImageCacheDebuggingLevelMedium;
