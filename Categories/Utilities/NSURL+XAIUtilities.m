//
//  NSURL+XAIUtilities.m
//  XAILibrary Category
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/28/14.
//  Copyright (c) 2011-2014 Black Panther White Leopard. All rights reserved.
//

#import "NSURL+XAIUtilities.h"

@implementation NSURL (XAIUtilities)

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
+ (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
