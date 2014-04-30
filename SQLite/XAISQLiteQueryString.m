//
//  XAISQLiteQueryString.m
//  XAISQLiteStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/30/14.
//  Copyright (c) 2014 Black Panther White Leopard. All rights reserved.
//

#import "XAISQLiteQueryString.h"
#import "XAISQLiteDefines.h"

@interface XAISQLiteQueryString()

- (NSArray *)bindPartsForColumnNames:(NSArray *)columnNames;

@property (nonatomic, strong) NSMutableString *queryString;

@end

@implementation XAISQLiteQueryString

#pragma mark - Init

- (instancetype)initWithCharactersNoCopy:(unichar *)characters length:(NSUInteger)length freeWhenDone:(BOOL)freeBuffer {
    self = [super init];
    
    if (self) {
        // Custom initialization.
        self.queryString = [[NSMutableString alloc] initWithCharactersNoCopy:characters length:length freeWhenDone:YES];
    }
    
    return self;
}

- (NSUInteger)length {
    return self.queryString.length;
}

- (unichar)characterAtIndex:(NSUInteger)index {
    return [self.queryString characterAtIndex:index];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString *)aString {
    [self.queryString replaceCharactersInRange:range withString:aString];
}

#pragma mark - NSMutableString - Append SELECT

- (void)appendFieldNames:(NSArray *)columnNames {
    [self appendFieldNames:columnNames keyedColumns:YES];
}

- (void)appendFieldNames:(NSArray *)columnNames keyedColumns:(BOOL)keysAsColumns {
    // Check to see if specific fields (columns) should be returned, or all fields.
    if ((keysAsColumns == YES) && ((columnNames != nil) && ([columnNames count] > 0))) {
        [self appendFormat:@"%@`%@`", kXAISQLiteStorageQueryLineSeparator, [columnNames componentsJoinedByString:@"`, `"]];
    } else {
        [self appendFormat:@"%@*", kXAISQLiteStorageQueryLineSeparator];
    }
}

#pragma mark - NSMutableString - Append TABLE

- (void)appendTableName:(NSString *)aTableName {
    [self appendTableName:aTableName includeFromPrefix:YES];
}

- (void)appendTableName:(NSString *)aTableName includeFromPrefix:(BOOL)includePrefix {
    [self appendFormat:@"%@%@`%@`", ((includePrefix) ? kXAISQLiteStorageQueryLineSeparator : @" "), ((includePrefix) ? @"FROM " : @""), aTableName];
}

#pragma mark - NSMutableString - Append SET

- (void)appendSetColumnNames:(NSArray *)columnNames {
    NSArray *queryParts = [self bindPartsForColumnNames:columnNames];
    
    // Check to see if the SET values need to be appended.
    if ([queryParts count] > 0) {
        // Add in the query parts, for the prepare statement binding.
        [self appendFormat:@"%@SET %@", kXAISQLiteStorageQueryLineSeparator, [queryParts componentsJoinedByString:@", "]];
    }
}

#pragma mark - NSMutableString - Append WHERE/AND

- (void)appendWhereColumnNames:(NSArray *)columnNames {
    NSArray *queryParts = [self bindPartsForColumnNames:columnNames];
    
    // Check to see if the WHERE values need to be appended.
    if ([queryParts count] > 0) {
        NSString *joinContent = [[NSString alloc] initWithFormat:@"%@AND", kXAISQLiteStorageQueryLineSeparator];
        
        // Add in the query parts, for the prepare statement binding.
        [self appendFormat:@"%@WHERE %@", kXAISQLiteStorageQueryLineSeparator, [queryParts componentsJoinedByString:joinContent]];
    }
}

#pragma mark - NSMutableString - Append OFFSET/LIMIT

- (void)appendLimit:(NSUInteger)aLimit offset:(NSUInteger)anOffset {
    // Check to see if the LIMIT needs to be added.
    if (aLimit != NSNotFound) {
        [self appendFormat:@"%@LIMIT %ld", kXAISQLiteStorageQueryLineSeparator, aLimit];
    }
    
    // Check to see if the OFFSET needs to be added.
    if (anOffset != NSNotFound) {
        [self appendFormat:@"%@OFFSET %ld", kXAISQLiteStorageQueryLineSeparator, anOffset];
    }
    
    // Add the ending delimiter.
    [self appendString:@";"];
}

#pragma mark - NSArray

- (NSArray *)bindPartsForColumnNames:(NSArray *)columnNames {
    // Check to see if the bind parameters need to be added.
    if ([columnNames count] == 0) {
        return nil;
    }
    
    NSMutableArray *queryParts = [[NSMutableArray alloc] initWithCapacity:[columnNames count]];
    
    // Prepare the column names for the various parts to bind to.
    for (NSString *aColumnName in columnNames) {
        NSString *preparePart = [[NSString alloc] initWithFormat:@"%@`%@` = ?", kXAISQLiteStorageQueryLineSeparator, aColumnName];
        
        [queryParts addObject:preparePart];
    }
    
    return queryParts;
}

@end
