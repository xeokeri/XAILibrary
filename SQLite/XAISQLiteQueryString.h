//
//  XAISQLiteQueryString.h
//  XAISQLiteStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/30/14.
//  Copyright (c) 2014 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XAISQLiteQueryString : NSMutableString

- (void)appendTableName:(NSString *)aTableName;
- (void)appendTableName:(NSString *)aTableName includeFromPrefix:(BOOL)includePrefix;
- (void)appendFieldNames:(NSArray *)columnNames;
- (void)appendFieldNames:(NSArray *)columnNames keyedColumns:(BOOL)keysAsColumns;
- (void)appendSetColumnNames:(NSArray *)columnNames;
- (void)appendWhereColumnNames:(NSArray *)columnNames;
- (void)appendLimit:(NSUInteger)aLimit offset:(NSUInteger)anOffset;

@end
