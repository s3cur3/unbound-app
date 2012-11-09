//
//  AlbumiViewController.h
//  Unbound
//
//  Created by Bob on 11/5/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PIViewController.h"

@interface IconViewBox : NSBox
{
	IBOutlet id delegate;
}
@end

/*@interface MyScrollView : NSScrollView
{
    NSGradient *backgroundGradient;
}
@end*/

@interface AlbumViewController : PIViewController <NSCollectionViewDelegate>
{
    IBOutlet NSCollectionView *collectionView;
    IBOutlet NSArrayController *arrayController;
    //NSMutableArray *images;
    
    //NSUInteger sortingMode;
    //BOOL alternateColors;
    
    NSArray *savedAlternateColors;
}

@property (strong) NSMutableArray *albums;
@property (strong) NSMutableArray *images;
@property (nonatomic, assign) NSUInteger sortingMode;
@property (nonatomic, assign) BOOL alternateColors;
//@property IBOutlet NSCollectionView *collectionView;
//@property IBOutlet NSArrayController *arrayController;


- (NSCollectionViewItem *)newItemForRepresentedObject:(id)object;

- (void)doubleClick:(id)sender;

-(void)updateContent:(NSMutableArray *)newContent;

@end
