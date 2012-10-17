//
//  SpotlightFetchController.h
//  Unbound5
//
//  Created by Bob on 10/16/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *SearchResultsDidChangeNotification;
extern NSString *SearchDidFinishNotification;

@interface SpotlightFetchController : NSObject <NSMetadataQueryDelegate>
{
    //NSURL *_searchURL;
@private
    NSMetadataQuery *_query;
    NSString *_title;
    NSArray *_children;
}

@property (strong) NSURL *_searchURL;

- (id)initWithSearchPredicate:(NSPredicate *)searchPredicate title:(NSString *)title scopeURL:(NSURL *)url;

- (NSString *)title;
- (NSArray *)children;

@end
