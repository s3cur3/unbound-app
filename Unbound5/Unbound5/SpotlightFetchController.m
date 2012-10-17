//
//  SpotlightFetchController.m
//  Unbound5
//
//  Created by Bob on 10/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "SpotlightFetchController.h"
#import "Photo.h"

NSString *SearchResultsDidChangeNotification = @"SearchResultsDidChangeNotification";
NSString *SearchDidFinishNotification = @"SearchDidFinishNotification";

@implementation SpotlightFetchController

- (id)initWithSearchPredicate:(NSPredicate *)searchPredicate title:(NSString *)title scopeURL:(NSURL *)url {
    self = [super init];
    if (self)
    {
        //_title = [title retain];
        _query = [[NSMetadataQuery alloc] init];
        self._searchURL = url;
        
        // We want the items in the query to automatically be sorted by the file system name;
        // this way, we don't have to do any special sorting
        [_query setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:(id)kMDItemFSName ascending:YES]]];
        [_query setPredicate:searchPredicate];
        
        // Use KVO to watch the results of the query
        [_query addObserver:self forKeyPath:@"results" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [_query setDelegate:self];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNote:) name:NSMetadataQueryDidFinishGatheringNotification object:_query];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNote:) name:nil object:_query];
        
        // define the scope/where the search will take placce
        [_query setSearchScopes:(url != nil) ? [NSArray arrayWithObject:url] : nil];
        
        [_query startQuery];
    }
    return self;
}

- (void)dealloc {
    [_query removeObserver:self forKeyPath:@"results"];
}

- (void)sendChildrenDidChangeNote {
    [[NSNotificationCenter defaultCenter] postNotificationName:SearchResultsDidChangeNotification object:self];
}

- (void)sendQueryDidFinishNote {
    [[NSNotificationCenter defaultCenter] postNotificationName:SearchDidFinishNotification object:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    // Delegate the KVO notification by sending a children changed note.
    // We could check the keyPath, but there is no need, since we only observe one value.
    //
#ifdef DEBUG
    NSArray *oldVals = self.children;
    //NSArray *oldVals = (NSArray *)[change valueForKey:@"old"];
    NSArray *newVals = (NSArray *)[change valueForKey:@"new"];
    NSInteger oldCount = [oldVals count];
    NSInteger newCount = [newVals count];
    DLog(@"\nCur #:%ld \nNew #:%ld", [oldVals count], [newVals count]);
    if (oldCount > newCount)
    {
        //Something was removed
        NSMutableArray *intermediate = [NSMutableArray arrayWithArray:oldVals];
        [intermediate removeObjectsInArray:newVals];
        NSUInteger difference = [intermediate count];
        DLog(@"%ld item(s) removed : ", difference);
    } else if (newCount > oldCount) {
        //Something was added
        NSMutableArray *intermediate = [NSMutableArray arrayWithArray:newVals];
        [intermediate removeObjectsInArray:oldVals];
        NSUInteger difference = [intermediate count];
        DLog(@"%ld item(s) added : ", difference);
    } else {
        //Same number of items
        NSMutableArray *intermediate = [NSMutableArray arrayWithArray:oldVals];
        [intermediate removeObjectsInArray:newVals];
        NSUInteger difference = [intermediate count];
        DLog(@"%ld item(s) differ : ", difference);
    }
#endif
    //[_children release];
    _children = [_query results];
    [self sendChildrenDidChangeNote];
}

#pragma NSMetadataQuery Delegate

- (id)metadataQuery:(NSMetadataQuery *)query replacementObjectForResultObject:(NSMetadataItem *)result {
    // We keep our own search item for the result in order to maintian state (image, thumbnail, title, etc)
    return [[Photo alloc] initWithMetadataItem:result];
}

- (void)queryNote:(NSNotification *)note {
    // The NSMetadataQuery will send back a note when updates are happening.
    // By looking at the [note name], we can tell what is happening
    //
    if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        [self sendQueryDidFinishNote];
    }
}

#pragma mark -

- (NSString *)title {
    return _title;
}

- (NSArray *)children {
    return _children;
}

@end
