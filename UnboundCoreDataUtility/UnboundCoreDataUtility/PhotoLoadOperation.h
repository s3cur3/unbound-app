//
//  PhotoLoadOperation.h
//  Unbound Mac
//
//  Created by Robert Edmonston on 12/31/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PhotoLoadOperation : NSOperation
{
    NSDateFormatter *dateFormatter;
    NSUInteger itemCounter;
}

- (id)initWithData:(NSArray *)newItems;

@property (copy, readonly) NSArray *items;
@property (strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSMutableArray *currentParseBatch;

@end
