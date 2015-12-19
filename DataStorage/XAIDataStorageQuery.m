//
//  XAIDataStorageQuery.m
//  XAIDataStorage
//
//  Created by Xeon Xai <xeonxai@me.com> on 4/10/12.
//  Copyright (c) 2012 Black Panther White Leopard. All rights reserved.
//

#import "XAIDataStorageQuery.h"
#import "XAIDataStorage.h"

/** XAILogging */
#import "NSError+XAILogging.h"
#import "NSException+XAILogging.h"

@interface XAIDataStorageQuery ()

- (NSFetchRequest *)fetchRequest;

@property (nonatomic, strong, readwrite) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, unsafe_unretained, readwrite) id <NSFetchedResultsControllerDelegate> fetchDelegate;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *fetchQueryContext;
@property (nonatomic, strong, readwrite) NSMutableArray <NSPredicate *> *filterPredicates;

@end

@implementation XAIDataStorageQuery

@synthesize fetchedResultsController    = _fetchedResultsController;
@synthesize fetchQueryContext           = _fetchQueryContext;
@synthesize fetchDelegate               = _fetchDelegate;
@synthesize filterEntityName            = _filterEntityName;
@synthesize filterTemplateName          = _filterTemplateName;
@synthesize filterTemplateSubstitutes   = _filterTemplateSubstitutes;
@synthesize filterSortKey               = _filterSortKey;
@synthesize filterSectionKeyPath        = _filterSectionKeyPath;
@synthesize filterSortOrderAscending    = _filterSortOrderAscending;
@synthesize filterPredicates            = _filterPredicates;

- (instancetype)init {
    self = [super init];
    
    if (self) {
        /** Self defaults. */
        _fetchDelegate = self;
    }
    
    return self;
}

- (instancetype)initWithDelegate:(id <NSFetchedResultsControllerDelegate>)incomingDelegate {
    self = [super init];
    
    if (self) {
        _fetchDelegate     = incomingDelegate;
    }
    
    return self;
}

- (instancetype)initWithContext:(NSManagedObjectContext *)incomingContext delegate:(id <NSFetchedResultsControllerDelegate>)incomingDelegate {
    self = [super init];
    
    if (self) {
        _fetchQueryContext = incomingContext;
        _fetchDelegate     = incomingDelegate;
    }
    
    return self;
}

- (instancetype)initWithContext:(NSManagedObjectContext *)incomingContext {
    self = [self init];
    
    if (self) {
        _fetchQueryContext = incomingContext;
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
    
    _fetchedResultsController.delegate = nil;
    
    _fetchedResultsController   = nil;
    _fetchQueryContext          = nil;
    _fetchDelegate              = nil;
    _filterPredicates           = nil;
    _filterTemplateName         = nil;
    _filterTemplateSubstitutes  = nil;
    _filterEntityName           = nil;
    _filterSortKey              = nil;
    _filterSectionKeyPath       = nil;
    
    #if !__has_feature(objc_arc)
        [super dealloc];
    #endif
}

#pragma mark - Reset Defaults

- (void)reset {
    if (_fetchedResultsController != nil) {
        _fetchedResultsController.delegate = nil;
        _fetchedResultsController          = nil;
    }
    
    /** Nil objects */
    [self setFilterEntityName:nil];
    [self setFilterPredicates:nil];
    [self setFilterSectionKeyPath:nil];
    [self setFilterTemplateName:nil];
    [self setFilterTemplateSubstitutes:nil];
    
    /** Sorting Defaults */
    [self setFilterSortKey:nil];
    [self setFilterSortOrderAscending:YES];
}

#pragma mark - NSPredicate

- (NSMutableArray *)filterPredicates {
    if (_filterPredicates) {
        return _filterPredicates;
    }
    
    _filterPredicates = [[NSMutableArray alloc] init];
    
    return _filterPredicates;
}

- (void)addPredicate:(NSPredicate *)aPredicate {
    if (!aPredicate) {
        NSLog(@"Predicate is nil. Unable to add predicate.");
        
        return;
    }
    
    [self.filterPredicates addObject:aPredicate];
}

- (void)addPredicateForColumnName:(NSString *)columnName withValue:(id)columnValue {
    if (!columnName || !columnValue) {
        NSLog(@"Column name {%@} or value {%@} is nil. Unable to add predicate.", columnName, columnValue);
        
        return;
    }
    
    NSPredicate *aPredicate = [NSPredicate predicateWithFormat:@"%K == %@", columnName, columnValue];
    
    [self.filterPredicates addObject:aPredicate];
}

#pragma mark - Fetched Objects Array

- (NSArray <NSManagedObject *> *)fetchObjects {
    return self.fetchedResultsController.fetchedObjects;
}

#pragma mark - NSArray

- (NSArray <NSDictionary <NSString *, id> *> *)fetchExpressionFunction:(NSString *)function column:(NSString *)column {
    // Create the fetch request for the entity.
    NSFetchRequest *aFetchRequest = [self fetchRequest];
    
    if (!aFetchRequest) {
        if (DEBUG) {
            NSLog(@"NSFetchRequest is nil.");
        }
        
        return nil;
    }
    
    if (!self.fetchQueryContext) {
        if (DEBUG) {
            NSLog(@"NSManagedObjectContext is nil.");
        }
        
        return nil;
    }
    
    if (column == nil || function == nil) {
        NSLog(@"Column {%@} or Function {%@} is nil. Unable to perform the expected Core Data function on the column.", column, function);
        
        return nil;
    }
    
    NSExpression *keyPathExpression  = [NSExpression expressionForKeyPath:column];
    NSExpression *functionExpression = [NSExpression expressionForFunction:function arguments:@[keyPathExpression]];
    
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];
    
    [expressionDescription setName:column];
    [expressionDescription setExpression:functionExpression];
    [expressionDescription setExpressionResultType:NSInteger32AttributeType];
    
    [aFetchRequest setResultType:NSDictionaryResultType];
    [aFetchRequest setPropertiesToFetch:@[expressionDescription]];
    
    NSError *error;
    NSArray *results = [self.fetchQueryContext executeFetchRequest:aFetchRequest error:&error];
    
    if (error != nil) {
        [error logDetailsFailedOnSelector:_cmd line:__LINE__];
        
        return nil;
    }
    
    return results;
}

#pragma mark - NSFetchRequest

- (NSFetchRequest *)fetchRequest {
    // Set up the fetched request controller.
    NSFetchRequest *aFetchRequest = nil;
    
    // Set the entity name.
    NSString *fetchEntityName = nil;
    
    if (self.filterEntityName != nil) {
        // Create the fetch request for the entity.
        aFetchRequest    = [NSFetchRequest fetchRequestWithEntityName:self.filterEntityName];
        fetchEntityName = self.filterEntityName;
    } else if (self.filterTemplateName != nil) {
        // Set up the managed object model.
        NSManagedObjectModel *managedObjectModel = [XAIDataStorage sharedStorage].managedObjectModel;
        
        aFetchRequest = (self.filterTemplateSubstitutes != nil && [self.filterTemplateSubstitutes count] > 0)
            ? [managedObjectModel fetchRequestFromTemplateWithName:self.filterTemplateName substitutionVariables:self.filterTemplateSubstitutes]
            : [managedObjectModel fetchRequestTemplateForName:self.filterTemplateName];
        
        fetchEntityName = [aFetchRequest entityName];
    } else {
        /** Do nothing. */
    }
    
    if ([self.filterPredicates count] > 0) {
        NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:self.filterPredicates];
        
        [aFetchRequest setPredicate:predicate];
    }
    
    if (!self.fetchQueryContext) {
        self.fetchQueryContext = [[XAIDataStorage sharedStorage] managedObjectContext];
    }
    
    // Set the fetch request entity.
    NSEntityDescription *entity = [NSEntityDescription entityForName:fetchEntityName inManagedObjectContext:self.fetchQueryContext];
    [aFetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [aFetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSArray *sortDescriptors = [[NSArray alloc] init];
    
    if ((self.filterSectionKeyPath != nil && self.filterSectionKeyPath.length > 0) && (self.filterSortKey != nil && self.filterSortKey.length > 0)) {
        NSArray *sortFilters = [[NSArray alloc] initWithObjects:self.filterSectionKeyPath, self.filterSortKey, nil];
        NSMutableArray *groupedSortDescriptors = [[NSMutableArray alloc] init];
        
        for (NSString *sortFilter in sortFilters) {
            NSSortDescriptor *filterDescriptor = [[NSSortDescriptor alloc] initWithKey:sortFilter ascending:self.isFilterSortOrderAscending];
            
            [groupedSortDescriptors addObject:filterDescriptor];
        }
        
        sortDescriptors = [[NSArray alloc] initWithArray:groupedSortDescriptors];
        
        #if !__has_feature(objc_arc)
            [groupedSortDescriptors release];
            [sortFilters release];
        #endif
    } else if ((self.filterSortKey != nil && self.filterSortKey.length > 0)) {
        NSSortDescriptor *filterSortKeyDescriptor = [[NSSortDescriptor alloc] initWithKey:self.filterSortKey ascending:self.isFilterSortOrderAscending];
        
        sortDescriptors = [[NSArray alloc] initWithObjects:filterSortKeyDescriptor, nil];
        
        #if !__has_feature(objc_arc)
            [filterSortKeyDescriptor release];
        #endif
    }
    
    [aFetchRequest setSortDescriptors:sortDescriptors];
    
    #if !__has_feature(objc_arc)
        [sortDescriptors release];
    #endif
    
    return aFetchRequest;
}

#pragma mark - NSFetchedResultsController

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *aFetchRequest = [self fetchRequest];
    
    if (!aFetchRequest) {
        if (DEBUG) {
            NSLog(@"NSFetchRequest is nil.");
        }
        
        return nil;
    }
    
    if (!self.fetchQueryContext) {
        if (DEBUG) {
            NSLog(@"NSManagedObjectContext is nil.");
        }
        
        return nil;
    }
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:aFetchRequest managedObjectContext:self.fetchQueryContext sectionNameKeyPath:self.filterSectionKeyPath cacheName:nil];
    aFetchedResultsController.delegate = self.fetchDelegate;
    self.fetchedResultsController = aFetchedResultsController;
    
    #if !__has_feature(objc_arc)
        [aFetchedResultsController release];
    #endif
    
    /** Lock the managed object context. */
    [self.fetchQueryContext performBlockAndWait:^{
        @try {
            NSError *error = nil;
            
            if (![self.fetchedResultsController performFetch:&error]) {
                [error logDetailsFailedOnSelector:_cmd line:__LINE__];
            }
        } @catch (NSException *exception) {
            [exception logDetailsFailedOnSelector:_cmd line:__LINE__ onClass:[[self class] description]];
        }
    }];
    
    return _fetchedResultsController;
}

@end
