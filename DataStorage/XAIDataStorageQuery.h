//
//  XAIDataStorageQuery.h
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/10/12.
//  Copyright (c) 2012-2015 Black Panther White Leopard. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface XAIDataStorageQuery : NSObject <NSFetchedResultsControllerDelegate> {

}

@property (nonatomic, unsafe_unretained, readonly) id <NSFetchedResultsControllerDelegate> fetchDelegate;
@property (nonatomic, strong, readonly) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong, readonly) NSManagedObjectContext *fetchQueryContext;
@property (nonatomic, strong, readonly) NSMutableArray <NSPredicate *> *filterPredicates;

/** Creates an NSFetchRequest for the Template Name with or without Substitute Values. */
@property (nonatomic, copy) NSString *filterTemplateName;
@property (nonatomic, strong) NSDictionary <NSString *, id> *filterTemplateSubstitutes;

/** Creates a NSFetchRequest for the Entity Name. */
@property (nonatomic, copy) NSString *filterEntityName;

/** Sort By. */
@property (nonatomic, copy) NSString *filterSortKey;

/** Order Ascending/Descending. */
@property (nonatomic, getter = isFilterSortOrderAscending) BOOL filterSortOrderAscending;

/** Group By (Sections) */
@property (nonatomic, copy) NSString *filterSectionKeyPath;

#pragma mark - Init

- (instancetype)initWithDelegate:(id <NSFetchedResultsControllerDelegate>)incomingDelegate;
- (instancetype)initWithContext:(NSManagedObjectContext *)incomingContext delegate:(id <NSFetchedResultsControllerDelegate>)incomingDelegate;
- (instancetype)initWithContext:(NSManagedObjectContext *)incomingContext;

#pragma mark - NSArray

- (NSArray <NSManagedObject *> *)fetchObjects;
- (NSArray <NSDictionary <NSString *, id> *> *)fetchExpressionFunction:(NSString *)function column:(NSString *)column;

- (void)addPredicate:(NSPredicate *)aPredicate;
- (void)addPredicateForColumnName:(NSString *)columnName withValue:(id)columnValue;

#pragma mark - Reset Filters to Defaults

- (void)reset;

@end