//
//  UIImage+XAIImageCache.h
//  XAIImageCache
//
//  Created by Xeon Xai <xeonxai@me.com> on 3/19/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (XAIImageCache)

/** UIImage Tile Crop */
- (void)cropIntoTilesWithSize:(CGSize)tileSize withCacheURLPrefix:(NSString *)prefix;

@end
