//
//  PIXBCCollectionViewController.h
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/10/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BCCollectionView;

@interface PIXBCCollectionViewController : NSViewController

@property(nonatomic,retain) IBOutlet BCCollectionView *collectionView;
@property(nonatomic,retain) NSMutableArray *imageContent;
@property(nonatomic,retain) NSMutableArray *albums;

@end
