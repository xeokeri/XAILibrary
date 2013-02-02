//
//  UIImage+XAIUtilities.h
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 12/9/11.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (XAIUtilities)

/** UIImage Screenshot from UIView */
+ (UIImage *)createImageFromView:(UIView *)captureView;

/** UIImage Crop */
- (UIImage *)cropInRect:(CGRect)rect;
- (UIImage *)cropInCenterForSize:(CGSize)size;
- (UIImage *)cropInCenterForSize:(CGSize)size withScaling:(BOOL)scaling;

/** UIImage Rotate & Scale */
+ (UIImage *)resizedCachedImageWithFilePath:(NSURL *)imagePath;

/** UIImage Scale */
- (UIImage *)scaleAspectRatioToMaxTileSize;

/** UIImage Resize */
- (UIImage *)resizeToFillThenCropToSize:(CGSize)size;
- (UIImage *)resizeToFillSize:(CGSize)size;

/** UIImage Color Overlay */
- (UIImage *)colorOverlay:(UIColor *)color;

/** UIImage Rotate */
- (UIImage *)fixImageOrientation;

@end
