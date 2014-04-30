//
//  XAISQLiteStorage.h
//  XAISQLiteStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/28/14.
//  Copyright (c) 2014 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

@interface XAISQLiteStorage : NSObject {
    sqlite3 *instanceDatabase;
}

+ (instancetype)sharedStorage;

- (NSArray *)fetchResultsWithArray:(NSArray *)anArray forTable:(NSString *)aTable;
- (NSArray *)fetchResultsWithArray:(NSArray *)anArray forTable:(NSString *)aTable limit:(NSUInteger)rowLimit;
- (NSArray *)fetchResultsWithArray:(NSArray *)anArray forTable:(NSString *)aTable limit:(NSUInteger)rowLimit offset:(NSUInteger)offset;
- (NSArray *)fetchResultsWithDictionary:(NSDictionary *)aDict keyedColumns:(BOOL)keysAsColumns forTable:(NSString *)aTable;
- (NSArray *)fetchResultsWithDictionary:(NSDictionary *)aDict keyedColumns:(BOOL)keysAsColumns forTable:(NSString *)aTable limit:(NSUInteger)rowLimit;
- (NSArray *)fetchResultsWithDictionary:(NSDictionary *)aDict keyedColumns:(BOOL)keysAsColumns forTable:(NSString *)aTable limit:(NSUInteger)rowLimit offset:(NSUInteger)offset;
- (NSArray *)fetchResultsWithQuery:(NSString *)aQuery;

- (BOOL)insertRecords:(NSArray *)records forTable:(NSString *)aTable;   // Insert multiple records at once.
- (BOOL)insertRecord:(NSDictionary *)aDict forTable:(NSString *)aTable; // Insert a single record.
- (BOOL)deleteRecord:(NSDictionary *)aDict forTable:(NSString *)aTable; // Delete single or multiple records at once.
- (BOOL)updateRecord:(NSDictionary *)aDict forTable:(NSString *)aTable updateDict:(NSDictionary *)updateDict; // Update single or multiple records at once.

@end
