//
//  PIXBCAlbumViewController.h
//  UnboundApp
//
//  Created by Bob on 1/16/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXViewController.h"
#import "BCCollectionView.h"

@interface PIXBCAlbumViewController : PIXViewController <BCCollectionViewDelegate>

@property(nonatomic,strong) IBOutlet BCCollectionView *collectionView;
@property(nonatomic,strong) NSMutableArray *imageContent;

@end
