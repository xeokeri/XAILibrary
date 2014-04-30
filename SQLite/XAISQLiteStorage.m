//
//  XAISQLiteStorage.m
//  XAISQLiteStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/28/14.
//  Copyright (c) 2014 Black Panther White Leopard. All rights reserved.
//

#import "XAISQLiteStorage.h"
#import "XAISQLiteQueryString.h"
#import "XAISQLiteDefines.h"

/** XAIUtilities */
#import "NSString+XAIUtilities.h"

@interface XAISQLiteStorage()

- (NSString *)prepareBindPlaceholdersForLength:(NSUInteger)bindLength;
- (NSArray *)fetchResultsWithQuery:(NSString *)aQuery withBindValues:(NSArray *)values;
- (NSDictionary *)nextRowForStatement:(sqlite3_stmt *)aStatement;
- (BOOL)performQuery:(NSString *)aQuery withBindValues:(NSArray *)values;
- (void)bindValues:(NSArray *)objValues toStatement:(sqlite3_stmt *)aStatement;
- (void)bindValues:(NSArray *)objValues toStatement:(sqlite3_stmt *)aStatement forRow:(int)rowIndex;

@end

@implementation XAISQLiteStorage

+ (instancetype)sharedStorage {
    static XAISQLiteStorage *_instance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        NSString *databaseFilePath = [NSString applicationPathForFileName:kXAISQLiteStorageName ofType:@"sqlite"];
        sqlite3 *sharedDatabase;
        
        if (sqlite3_open([databaseFilePath UTF8String], &sharedDatabase) == SQLITE_OK) {
            _instance = [[XAISQLiteStorage alloc] init];
            _instance->instanceDatabase = sharedDatabase;
        } else {
            if (kXAISQLiteStorageDebugging) {
                // TODO: Migrate to use the alternate XAILibrary logging, when improved.
                NSLog(@"SQLite: Unable to load database file.");
            }
        }
    });
    
    return _instance;
}

#pragma mark - NSArray

/**
 * Fetch results using an array for the column names to return.
 */
- (NSArray *)fetchResultsWithArray:(NSArray *)anArray forTable:(NSString *)aTable {
    return [self fetchResultsWithArray:anArray forTable:aTable limit:NSNotFound offset:NSNotFound];
}

- (NSArray *)fetchResultsWithArray:(NSArray *)anArray forTable:(NSString *)aTable limit:(NSUInteger)rowLimit {
    return [self fetchResultsWithArray:anArray forTable:aTable limit:rowLimit offset:NSNotFound];
}

- (NSArray *)fetchResultsWithArray:(NSArray *)anArray forTable:(NSString *)aTable limit:(NSUInteger)rowLimit offset:(NSUInteger)offset {
    // Add the initial SELECT.
    XAISQLiteQueryString *aQuery = [[XAISQLiteQueryString alloc] initWithString:@"SELECT"];
    
    // Add SELECT fields, as needed.
    [aQuery appendFieldNames:anArray];
    
    // Add the FROM table.
    [aQuery appendTableName:aTable];
    
    // Append the LIMIT/OFFSET to the query.
    [aQuery appendLimit:rowLimit offset:offset];
    
    // Fetch the results with the formatted query.
    return [self fetchResultsWithQuery:aQuery];
}

/**
 * Fetch results using a dictionary with the keys for the column names, and the values for the search values.
 */
- (NSArray *)fetchResultsWithDictionary:(NSDictionary *)aDict keyedColumns:(BOOL)keysAsColumns forTable:(NSString *)aTable {
    return [self fetchResultsWithDictionary:aDict keyedColumns:keysAsColumns forTable:aTable limit:NSNotFound offset:NSNotFound];
}

- (NSArray *)fetchResultsWithDictionary:(NSDictionary *)aDict keyedColumns:(BOOL)keysAsColumns forTable:(NSString *)aTable limit:(NSUInteger)rowLimit {
    return [self fetchResultsWithDictionary:aDict keyedColumns:keysAsColumns forTable:aTable limit:rowLimit offset:NSNotFound];
}

- (NSArray *)fetchResultsWithDictionary:(NSDictionary *)aDict keyedColumns:(BOOL)keysAsColumns forTable:(NSString *)aTable limit:(NSUInteger)rowLimit offset:(NSUInteger)offset {
    NSArray
        *columnNames  = [aDict allKeys],   // Column names to display in the results set, if keys are used as columns.
        *columnValues = [aDict allValues]; // Column values to bind the parameter placeholders to.
    
    // Add the initial SELECT.
    XAISQLiteQueryString *aQuery = [[XAISQLiteQueryString alloc] initWithString:@"SELECT"];
    
    // Add SELECT fields, as needed.
    [aQuery appendFieldNames:columnNames keyedColumns:keysAsColumns];
    
    // Add the FROM table.
    [aQuery appendTableName:aTable];
    
    // Append WHERE/AND params and binding content as needed.
    [aQuery appendWhereColumnNames:columnNames];
    
    // Append the LIMIT/OFFSET to the query.
    [aQuery appendLimit:rowLimit offset:offset];
    
    // Fetch the results with the formatted query.
    return [self fetchResultsWithQuery:aQuery withBindValues:columnValues];
}

/**
 * Fetch results using a pre formatted query string.
 */
- (NSArray *)fetchResultsWithQuery:(NSString *)aQuery {
    return [self fetchResultsWithQuery:aQuery withBindValues:nil];
}

/**
 * Fetch results with an assembled bind query string.
 */
- (NSArray *)fetchResultsWithQuery:(NSString *)aQuery withBindValues:(NSArray *)values {
    sqlite3_stmt *fetchStatement = NULL;
    const char *sqlQuery         = [aQuery UTF8String];
    
    // Check for query debugging.
    if (kXAISQLiteStorageDebugging) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"%s -> %@", __PRETTY_FUNCTION__, aQuery);
    }
    
    if (sqlite3_prepare_v2(self->instanceDatabase, sqlQuery, -1, &fetchStatement, NULL) != SQLITE_OK) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error when preparing the query.");
    } else {
        // Prepare the filtered results.
        NSMutableArray *results = [[NSMutableArray alloc] init];
        
        // Check to see if there should be any parameter binding to the query.
        if (values != nil && ([values count] > 0)) {
            // Bind all values to the query statement.
            [self bindValues:values toStatement:fetchStatement];
        }
        
        // Loop the query results set.
        while (sqlite3_step(fetchStatement) == SQLITE_ROW) {
            // Filter the row data.
            NSDictionary *row = [self nextRowForStatement:fetchStatement];
            
            // Add the row to the results.
            [results addObject:row];
        }
        
        // Check to see if the results should be displayed for debugging.
        if (kXAISQLiteStorageDebugging) {
            // TODO: Migrate to use the alternate XAILibrary logging, when improved.
            NSLog(@"Results: %@", results);
        }
        
        // Close the statement.
        sqlite3_finalize(fetchStatement);
        
        return results;
    }
    
    return nil;
}

#pragma mark - NSDictionary

- (NSDictionary *)nextRowForStatement:(sqlite3_stmt *)aStatement {
    NSMutableDictionary *row = [[NSMutableDictionary alloc] init];
    int columnCount          = sqlite3_column_count(aStatement);
    
    for (int idx = 0; idx < columnCount; idx++) {
        int columnType            = sqlite3_column_type(aStatement, idx);
        const char *columnName    = sqlite3_column_name(aStatement, idx);
        NSString *cleanColumnName = [[NSString alloc] initWithUTF8String:columnName];
        
        switch (columnType) {
                // Filter the text results.
            case SQLITE_TEXT: {
                const unsigned char *columnText = sqlite3_column_text(aStatement, idx);
                NSString *filteredText          = [[NSString alloc] initWithFormat:@"%s", columnText];
                
                [row setObject:filteredText forKey:cleanColumnName];
            }
                
                break;
                
                // Filter the integer results.
            case SQLITE_INTEGER: {
                int columnInt            = sqlite3_column_int(aStatement, idx);
                NSNumber *filteredNumber = [[NSNumber alloc] initWithInt:columnInt];
                
                [row setObject:filteredNumber forKey:cleanColumnName];
            }
                
                break;
                
                // Filter the float results.
            case SQLITE_FLOAT: {
                double columnDouble             = sqlite3_column_double(aStatement, idx);
                NSDecimalNumber *filteredNumber = [[NSDecimalNumber alloc] initWithDouble:columnDouble];
                
                [row setObject:filteredNumber forKey:cleanColumnName];
            }
                
                break;
                
                // Filter the blob results.
            case SQLITE_BLOB: {
                NSUInteger blobLength = (NSUInteger) abs(sqlite3_column_bytes(aStatement, idx));
                NSData *blobData      = [[NSData alloc] initWithBytes:sqlite3_column_blob(aStatement, idx) length:blobLength];
                
                [row setObject:blobData forKey:cleanColumnName];
            }
                
                break;
                
                // Filter for the null values.
            case SQLITE_NULL: {
                // Null content.
                [row setObject:[NSNull null] forKey:cleanColumnName];
            }
                
                break;
                
                // Filter for the unknown data types.
            default: {
                // TODO: Migrate to use the alternate XAILibrary logging, when improved.
                NSLog(@"SQLite: Column unknown data type for column name `%@` at row `%d`.", cleanColumnName, idx);
            }
                
                break;
        }
    }
    
    return row;
}

#pragma mark - INSERT

/**
 * Insert multiple records at once.
 */
- (BOOL)insertRecords:(NSArray *)records forTable:(NSString *)aTable {
    // Check to see if there are actual values.
    if (records == nil || ([records count] == 0) || aTable == nil) {
        return NO;
    }
    
    NSArray *recordMatchKeys  = nil;
    NSMutableArray *rowValues = [[NSMutableArray alloc] initWithCapacity:[records count]];
    
    // Process each record, to see how it should be inserted.
    for (NSDictionary *aRecord in records) {
        // Check the first record for the keys to use, for the column names.
        if (recordMatchKeys == nil) {
            recordMatchKeys = [aRecord allKeys];
        } else {
            // Any rows not matching the same keys for the master keys, should be inserted individually.
            if (![[aRecord allKeys] isEqualToArray:recordMatchKeys]) {
                [self insertRecord:aRecord forTable:aTable];
                
                // Skip to the next record.
                continue;
            }
        }
        
        // Add in the values to be used in the bind for the row insert.
        [rowValues addObject:[aRecord allValues]];
    }
    
    NSMutableString *aQuery     = [[NSMutableString alloc] init];
    NSString *valuesPlaceholder = [self prepareBindPlaceholdersForLength:[recordMatchKeys count]];
    
    // Begin preparing the INSERT query, with bind placeholders.
    [aQuery appendFormat:@"INSERT INTO `%@` (`%@`) VALUES ", aTable, [recordMatchKeys componentsJoinedByString:@"`, `"]];
    
    // Process each row for the insert, to add in all the bind placeholders.
    for (NSUInteger idx = 0; idx < [rowValues count]; idx++) {
        // Format each placeholder row accordingly, so that the last row has the semicolon delimited, and other rows have the comma delimiter.
        [aQuery appendFormat:@"%@%@%@", kXAISQLiteStorageQueryLineSeparator, valuesPlaceholder, ((idx == ([rowValues count] - 1)) ? @";" : @"," )];
    }
    
    // Perform the query and check the result status.
    BOOL successStatus = [self performQuery:aQuery withBindValues:rowValues];
    
    // Check the INSERT.
    if (!successStatus) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error inserting rows.");
    }
    
    return successStatus;
}

/**
 * Insert a single record.
 */
- (BOOL)insertRecord:(NSDictionary *)aDict forTable:(NSString *)aTable {
    // Check to see if there are actual values.
    if (aDict == nil || aTable == nil) {
        return NO;
    }
    
    NSArray
        *columnNames  = [aDict allKeys],   // Column names to display in the results set, if keys are used as columns.
        *columnValues = [aDict allValues]; // Column values to bind the parameter placeholders to.
    
    NSMutableString *aQuery     = [[NSMutableString alloc] init];
    NSString *valuesPlaceholder = [self prepareBindPlaceholdersForLength:[columnValues count]];
    
    // Begin preparing the INSERT query, with bind placeholders.
    [aQuery appendFormat:@"INSERT INTO `%@` (`%@`) VALUES %@;", aTable, [columnNames componentsJoinedByString:@"`, `"], valuesPlaceholder];
    
    // Perform the query and check the result status.
    BOOL successStatus = [self performQuery:aQuery withBindValues:columnValues];
    
    // Check the INSERT.
    if (!successStatus) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error inserting row.");
    }
    
    return successStatus;
}

#pragma mark - DELETE

/**
 * Delete a single or multiple records at once.
 */
- (BOOL)deleteRecord:(NSDictionary *)aDict forTable:(NSString *)aTable {
    // Check to see if there are actual values.
    if (aDict == nil || aTable == nil) {
        return NO;
    }
    
    NSArray
       *columnNames  = [aDict allKeys],
       *columnValues = [aDict allValues];
    
    // Start the DELETE query.
    XAISQLiteQueryString *aQuery = [[XAISQLiteQueryString alloc] initWithString:@"DELETE"];
    
    // Add the FROM table.
    [aQuery appendTableName:aTable];
    
    // Append WHERE/AND params and binding content as needed.
    [aQuery appendWhereColumnNames:columnNames];
    
    // Add the ending delimiter.
    [aQuery appendString:@";"];
    
    // Perform the query and check the result status.
    BOOL successStatus = [self performQuery:aQuery withBindValues:columnValues];
    
    // Check the DELETE.
    if (!successStatus) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error deleting row(s).");
    }
    
    return successStatus;
}

/**
 * UPDATE single or multiple records at once.
 */
- (BOOL)updateRecord:(NSDictionary *)aDict forTable:(NSString *)aTable updateDict:(NSDictionary *)updateDict {
    // Check to see if there are actual values.
    if (aDict == nil || aTable == nil || updateDict == nil) {
        return NO;
    }
    
    NSArray
        *selectNames  = [aDict allKeys],
        *selectValues = [aDict allValues],
        *updateNames  = [updateDict allKeys],
        *updateValues = [updateDict allValues];
    
    NSUInteger
        paramsCount   = ([updateValues count] + [selectValues count]);
    
    NSMutableArray
        *bindValues   = [[NSMutableArray alloc] initWithCapacity:paramsCount];
    
    // Add the SET bind values.
    [bindValues addObjectsFromArray:updateValues];
    
    // Add the WHERE bind values.
    [bindValues addObjectsFromArray:selectValues];
    
    // Start the UPDATE query.
    XAISQLiteQueryString *aQuery = [[XAISQLiteQueryString alloc] initWithString:@"UPDATE"];
    
    // Add the FROM table.
    [aQuery appendTableName:aTable includeFromPrefix:NO];
    
    // Add the SET params and binding content as needed.
    [aQuery appendSetColumnNames:updateNames];
    
    // Append WHERE/AND params and binding content as needed.
    [aQuery appendWhereColumnNames:selectNames];
    
    // Add the ending delimiter.
    [aQuery appendString:@";"];
    
    // Perform the query and check the result status.
    BOOL successStatus = [self performQuery:aQuery withBindValues:bindValues];
    
    // Check the UPDATE.
    if (!successStatus) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error updating the row(s).");
    }
    
    return successStatus;
}

- (BOOL)performQuery:(NSString *)aQuery withBindValues:(NSArray *)values {
    // Statement for the sqlite query.
    sqlite3_stmt *queryStatement = NULL;
    
    // Prepare the query, and store the result code.
    int resultCode = sqlite3_prepare(self->instanceDatabase, [aQuery UTF8String], -1, &queryStatement, NULL);
    
    // Check the result code to see if the prepare step was successful.
    if (resultCode != SQLITE_OK) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error performing prepared statement with error code: %d\nQuery: %@", resultCode, aQuery);
        
        return NO;
    }
    
    // Bind all values to the query statement.
    [self bindValues:values toStatement:queryStatement];
    
    // Execute the INSERT.
    resultCode = sqlite3_step(queryStatement);
    
    if (resultCode != SQLITE_DONE) {
        // TODO: Migrate to use the alternate XAILibrary logging, when improved.
        NSLog(@"SQLite: Error performing step with error code: %d", resultCode);
    }
    
    // Close the statement.
    sqlite3_finalize(queryStatement);
    
    return (resultCode == SQLITE_DONE);
}

#pragma mark - NSString

- (NSString *)prepareBindPlaceholdersForLength:(NSUInteger)bindLength {
    NSString
        *bindPlaceholderEmpty     = @"",
        *bindPlaceholderLeftSide  = @"?, ",
        *bindPlaceholderRightSide = @"?",
        *bindPlaceholderContent   = (bindLength == 0)
            ? bindPlaceholderEmpty
            : (bindLength >= 2)
                ? bindPlaceholderLeftSide
                : bindPlaceholderRightSide;
    
    // Check to see how long the placeholder should be based on the number of items to bind and the length of the bind placeholder.
    NSUInteger filteredPlaceholderLength = (((bindLength >= 2) ? (bindLength - 1) : bindLength) * [bindPlaceholderContent length]);
    NSString *filteredBindContent        = [bindPlaceholderEmpty stringByPaddingToLength:filteredPlaceholderLength withString:bindPlaceholderContent startingAtIndex:0];
    
    // More than one, append the end content.
    if (bindLength >= 2) {
        filteredBindContent = [filteredBindContent stringByAppendingString:bindPlaceholderRightSide];
    }
    
    return [[NSString alloc] initWithFormat:@"(%@)", filteredBindContent];
}

#pragma mark - SQLite3 Statement Bind

- (void)bindValues:(NSArray *)objValues toStatement:(sqlite3_stmt *)aStatement {
    [self bindValues:objValues toStatement:aStatement forRow:0];
}

- (void)bindValues:(NSArray *)objValues toStatement:(sqlite3_stmt *)aStatement forRow:(int)rowIndex {
    // Bind all values to the query statement.
    for (id aValue in objValues) {
        // Array objects should process further, for multidimensional support.
        if ([aValue isKindOfClass:[NSArray class]]) {
            // Bind the values for the array separately.
            [self bindValues:aValue toStatement:aStatement forRow:rowIndex++];
            
            // Do not process any further.
            continue;
        }
        
        // Find the proper column index to bind the value to.
        unsigned long idx = (llabs((unsigned long) [objValues indexOfObject:aValue]) + 1);
        
        // The bindOffset for multidimensional arrays, should update the bind index.
        if (rowIndex > 0 ) {
            idx += (rowIndex * [objValues count]);
        }
        
        if ([aValue isKindOfClass:[NSString class]]) {
            // Bind text.
            sqlite3_bind_text(aStatement, (int) idx, [aValue UTF8String], -1, NULL);
        } else if ([aValue isKindOfClass:[NSData class]]) {
            // Bind Blob.
            sqlite3_bind_blob(aStatement, (int) idx, [aValue bytes], (int) [aValue length], NULL);
        } else if ([aValue isKindOfClass:[NSNumber class]]) {
            const char *objCTypeValue = [aValue objCType];
            
            if (strcmp(objCTypeValue, @encode(float)) == 0) {
                // Bind float/decimal.
                sqlite3_bind_double(aStatement, (int) idx, (double) [aValue doubleValue]);
            } else if (strcmp(objCTypeValue, @encode(int)) == 0) {
                // Bind integer.
                sqlite3_bind_int(aStatement, (int) idx, (int) [aValue intValue]);
            }
        } else if ([NSDecimalNumber class]) {
            // Bind float/decimal.
            sqlite3_bind_double(aStatement, (int) idx, (double) [aValue doubleValue]);
        } else if ([aValue isKindOfClass:[NSNull class]]) {
            // Bind null.
            sqlite3_bind_null(aStatement, (int) idx);
        } else {
            // Do nothing...
        }
    }
}

@end
