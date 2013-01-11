//
//  PIXAlbumViewController.h
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
//#import "PIXViewController.h"

@interface PIXAlbumViewController : NSViewController <NSCollectionViewDelegate>
{
    IBOutlet NSArrayController *arrayController;
    //IBOutlet NSCollectionView *collectionView;
}

@property (strong, nonatomic) NSMutableArray *albums;
@property (strong,nonatomic) IBOutlet NSCollectionView *collectionView;


@end


@interface IconViewBox : NSBox
{
	IBOutlet id delegate;
}
@end