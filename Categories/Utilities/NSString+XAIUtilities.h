//
//  NSString+XAIUtilities.h
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/28/14.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (XAIUtilities)

/** Application File Locations. */
+ (NSString *)applicationPathForFileName:(NSString *)fileName ofType:(NSString *)fileType;

/** HASH Encoding */
- (NSString *)md5HexEncode;
- (NSString *)sha256HexEncode;

@end
