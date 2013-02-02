//
//  XAIDataStorageQuery.h
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/10/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface XAIDataStorageQuery : NSObject <NSFetchedResultsControllerDelegate> {
    NSFetchedResultsController *fetchedResultsController;
    
    @private
    NSManagedObjectContext *fetchQueryContext;
    
    NSString     *filterTemplateName;
    NSString     *filterEntityName;
    NSString     *filterSortKey;
    NSString     *filterSectionKeyPath;
    NSPredicate  *filterPredicate;
    NSDictionary *filterPredicateSubstitutes;
    
    BOOL         filterSortOrderAscending;
}

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSManagedObjectContext *fetchQueryContext;
@property (nonatomic, strong) NSString *filterTemplateName;
@property (nonatomic, strong) NSString *filterEntityName;
@property (nonatomic, strong) NSString *filterSortKey;
@property (nonatomic, strong) NSString *filterSectionKeyPath;
@property (nonatomic, strong) NSDictionary *filterPredicateSubstitutes;
@property (nonatomic, strong) NSPredicate *filterPredicate;
@property (nonatomic, getter = isFilterSortOrderAscending) BOOL filterSortOrderAscending;

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate;
- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate withSortKey:(NSString *)sortKey;
- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder;
- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder groupBy:(NSString *)groupByKey;

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey;
- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder;
- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder groupBy:(NSString *)groupByKey;

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey predicateColumn:(NSString *)columnName predicateValue:(id)columnValue;
- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey predicateColumn:(NSString *)columnName predicateValue:(id)columnValue isAscending:(BOOL)sortOrder;

- (NSArray *)fetchedObjectsForTemplateName:(NSString *)fetchTemplateName withSubstitutes:(NSDictionary *)substitutes;
- (NSArray *)fetchedObjectsForTemplateName:(NSString *)fetchTemplateName withSubstitutes:(NSDictionary *)substitutes withSortKey:(NSString *)sortingKey;

- (id)initWithContext:(NSManagedObjectContext *)incomingContext;
- (id)initWithContext:(NSManagedObjectContext *)incomingContext withEntityName:(NSString *)entityName;

@end