//
//  XAIDataStorageQuery.m
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/10/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIDataStorageQuery.h"
#import "XAIDataStorage.h"
#import "XAIDataStorageDefines.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@interface XAIDataStorageQuery ()

- (void)resetDefaults;

@end

@implementation XAIDataStorageQuery

@synthesize fetchedResultsController = __fetchedResultsController;
@synthesize fetchQueryContext        = __fetchQueryContext;
@synthesize delegate                 = __delegate;

@synthesize filterTemplateName, filterEntityName, filterSortKey, filterSectionKeyPath;
@synthesize filterSortOrderAscending;
@synthesize filterPredicate, filterPredicateSubstitutes;

- (id)init {
    self = [super init];
    
    if (self) {
        /** Self defaults. */
        self.delegate                   = self;
        
        /** Nil defaults. */
        self.filterEntityName           = nil;
        self.filterTemplateName         = nil;
        self.filterPredicate            = nil;
        self.filterPredicateSubstitutes = nil;
        self.filterSectionKeyPath       = nil;
        self.filterSortKey              = nil;
        self.fetchQueryContext          = nil;
    }
    
    return self;
}

- (id)initWithDelegate:(id <NSFetchedResultsControllerDelegate>)incomingDelegate {
    self = [super init];
    
    if (self) {
        self.delegate = incomingDelegate;
    }
    
    return self;
}

- (id)initWithContext:(NSManagedObjectContext *)incomingContext {
    self = [self init];
    
    if (self) {
        self.fetchQueryContext = incomingContext;
    }
    
    return self;
}

- (id)initWithContext:(NSManagedObjectContext *)incomingContext withEntityName:(NSString *)entityName {
    self = [self init];
    
    if (self) {
        self.fetchQueryContext = incomingContext;
        self.filterEntityName  = entityName;
    }
    
    return self;
}

- (void)dealloc {
    #if !__has_feature(objc_arc)
        [filterPredicate release];
        [filterTemplateName release];
        [filterEntityName release];
        [filterSortKey release];
        [filterSectionKeyPath release];
        [filterPredicateSubstitutes release];
        [fetchQueryContext release];
        [fetchedResultsController release];
    #endif
    
    filterPredicate            = nil;
    filterPredicateSubstitutes = nil;
    filterTemplateName         = nil;
    filterEntityName           = nil;
    filterSortKey              = nil;
    filterSectionKeyPath       = nil;
    fetchQueryContext          = nil;
    fetchedResultsController   = nil;
    delegate                   = nil;
    
    #if !__has_feature(objc_arc)
        [super dealloc];
    #endif
}

#pragma mark - Reset Defaults

- (void)resetDefaults {
    if (__fetchedResultsController != nil) {
        __fetchedResultsController.delegate = nil;
        __fetchedResultsController          = nil;
    }
    
    /** Nil objects */
    [self setFilterEntityName:nil];
    [self setFilterPredicate:nil];
    [self setFilterPredicateSubstitutes:nil];
    [self setFilterSectionKeyPath:nil];
    [self setFilterTemplateName:nil];
    
    /** Sorting Defaults */
    [self setFilterSortKey:kXAIDataStorageDefaultSortKey];
    [self setFilterSortOrderAscending:kXAIDataStorageDefaultSortOrderAscending];
}

#pragma mark - Fetched Objects Array

- (NSArray *)fetchedObjectsForTemplateName:(NSString *)fetchTemplateName withSubstitutes:(NSDictionary *)substitutes {
    [self resetDefaults];
    
    self.filterTemplateName         = fetchTemplateName;
    self.filterPredicateSubstitutes = substitutes;
    
    return [self.fetchedResultsController fetchedObjects];
}

- (NSArray *)fetchedObjectsForTemplateName:(NSString *)fetchTemplateName withSubstitutes:(NSDictionary *)substitutes withSortKey:(NSString *)sortingKey {
    [self resetDefaults];
    
    self.filterSortKey              = sortingKey;
    self.filterTemplateName         = fetchTemplateName;
    self.filterPredicateSubstitutes = substitutes;
    
    return [self.fetchedResultsController fetchedObjects];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate {
    return [self fetchedObjectsForEntityName:entityName withPredicate:predicate withSortKey:kXAIDataStorageDefaultSortKey];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate withSortKey:(NSString *)sortKey {
    return [self fetchedObjectsForEntityName:entityName withPredicate:predicate withSortKey:sortKey isAscending:kXAIDataStorageDefaultSortOrderAscending];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder {
    return [self fetchedObjectsForEntityName:entityName withPredicate:predicate withSortKey:sortingKey isAscending:sortOrder groupBy:nil];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withPredicate:(NSPredicate *)predicate withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder groupBy:(NSString *)groupByKey {
    [self resetDefaults];
    
    self.filterSectionKeyPath     = groupByKey;
    self.filterSortKey            = sortingKey;
    self.filterSortOrderAscending = sortOrder;
    self.filterEntityName         = entityName;
    self.filterPredicate          = predicate;
    
    return [self.fetchedResultsController fetchedObjects];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder groupBy:(NSString *)groupByKey {
    [self resetDefaults];
    
    self.filterSectionKeyPath     = groupByKey;
    self.filterSortKey            = sortingKey;
    self.filterSortOrderAscending = sortOrder;
    self.filterEntityName         = entityName;
    
    return [self.fetchedResultsController fetchedObjects];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey {
    return [self fetchedObjectsForEntityName:entityName withSortKey:sortingKey isAscending:kXAIDataStorageDefaultSortOrderAscending];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey isAscending:(BOOL)sortOrder {
    return [self fetchedObjectsForEntityName:entityName withSortKey:sortingKey isAscending:sortOrder groupBy:nil];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey predicateColumn:(NSString *)columnName predicateValue:(id)columnValue {
    return [self fetchedObjectsForEntityName:entityName withSortKey:sortingKey predicateColumn:columnName predicateValue:columnValue isAscending:kXAIDataStorageDefaultSortOrderAscending];
}

- (NSArray *)fetchedObjectsForEntityName:(NSString *)entityName withSortKey:(NSString *)sortingKey predicateColumn:(NSString *)columnName predicateValue:(id)columnValue isAscending:(BOOL)sortOrder {
    [self resetDefaults];
    
    self.filterPredicate          = [NSPredicate predicateWithFormat:@"%K == %@", columnName, columnValue];
    self.filterSortKey            = sortingKey;
    self.filterSortOrderAscending = sortOrder;
    self.filterEntityName         = entityName;
    
    return [self.fetchedResultsController fetchedObjects];
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    if (__fetchedResultsController != nil) {
        return __fetchedResultsController;
    }
    
    // Set up the fetched request controller.
    NSFetchRequest *fetchRequest = nil;
    
    // Set the entity name.
    NSString *fetchEntityName = nil;
    
    if (self.filterEntityName != nil) {
        // Create the fetch request for the entity.
        fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:self.filterEntityName];
        fetchEntityName = self.filterEntityName;
    } else if (self.filterTemplateName != nil) {
        // Set up the managed object model.
        NSManagedObjectModel *managedObjectModel = [XAIDataStorage sharedStorage].managedObjectModel;
        
        fetchRequest    = [managedObjectModel fetchRequestFromTemplateWithName:self.filterTemplateName substitutionVariables:self.filterPredicateSubstitutes];
        fetchEntityName = [fetchRequest entityName];
    } else {
        /** Do nothing. */
    }
    
    if (self.filterPredicate) {
        [fetchRequest setPredicate:self.filterPredicate];
    }
    
    if (!self.fetchQueryContext) {
        self.fetchQueryContext = [[XAIDataStorage sharedStorage] managedObjectContext];
    }
    
    // Set the fetch request entity.
    NSEntityDescription *entity = [NSEntityDescription entityForName:fetchEntityName inManagedObjectContext:self.fetchQueryContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSArray *sortDescriptors = [NSArray array];
    
    if (self.filterSectionKeyPath) {
        NSArray *sortFilters = [NSArray arrayWithObjects:self.filterSectionKeyPath, self.filterSortKey, nil];
        NSMutableArray *groupedSortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSString *sortFilter in sortFilters) {
            NSSortDescriptor *filterDescriptor = [[NSSortDescriptor alloc] initWithKey:sortFilter ascending:self.isFilterSortOrderAscending];
            
            [groupedSortDescriptors addObject:filterDescriptor];
        }
        
        sortDescriptors = [NSArray arrayWithArray:groupedSortDescriptors];
        
        #if !__has_feature(objc_arc)
            [groupedSortDescriptors release];
        #endif
    } else {
        NSSortDescriptor *filterSortKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:self.filterSortKey ascending:self.isFilterSortOrderAscending];
        
        sortDescriptors = [NSArray arrayWithObjects:filterSortKeyDescriptor, nil];
        
        #if !__has_feature(objc_arc)
            [filterSortKeyDescriptor release];
        #endif
    }
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    if (!fetchRequest) {
        if (kXAIDataStorageDebugging) {
            NSLog(@"NSFetchRequest is nil.");
        }
        
        return nil;
    }
    
    if (!self.fetchQueryContext) {
        if (kXAIDataStorageDebugging) {
            NSLog(@"NSManagedObjectContext is nil.");
        }
        
        return nil;
    }
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.fetchQueryContext sectionNameKeyPath:self.filterSectionKeyPath cacheName:nil];
    aFetchedResultsController.delegate = self.delegate;
    self.fetchedResultsController = aFetchedResultsController;
    
    #if !__has_feature(objc_arc)
        [aFetchedResultsController release];
    #endif
    
    NSError *error = nil;
    
    /** Lock the managed object context. */
    [self.fetchQueryContext lock];
    
    @try {
        if (![self.fetchedResultsController performFetch:&error]) {
            [error logDetailsFailedOnSelector:_cmd line:__LINE__];
        }
    } @catch (NSException *exception) {
        [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
    }
    
    /** Unlock the managed object context. */
    [self.fetchQueryContext unlock];
    
    return __fetchedResultsController;
}

@end
