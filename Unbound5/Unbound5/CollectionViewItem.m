//
//  CollectionViewItem.m
//  Unbound
//
//  Created by Bob on 11/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "CollectionViewItem.h"
#import "Album.h"

@interface CollectionViewItem ()
{
    bool isSelected;
}

@end

@implementation CollectionViewItem

-(IBAction)deleteItem:(id)sender
{
    DLog(@"Delete Item");
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

-(void)awakeFromNib
{
   [self.view setWantsLayer:YES];
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    
    CGSize imageSize = [[(Album *)representedObject thumbnailImage] size];
    
    CGRect imageFrame = CGRectMake(0, 0, imageSize.width, imageSize.height);
    
    [self.borderLayer setFrame:imageFrame];
    
}


- (void)doubleClick:(id)sender {
	NSLog(@"double click in the collectionItem");
	if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
		[[[self collectionView] delegate] performSelector:@selector(doubleClick:) withObject:self];
	}
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"rightMouseDown:%@", theEvent);
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Options"];
    [theMenu insertItemWithTitle:@"Delete" action:@selector(deleteItem:) keyEquivalent:@""atIndex:0];
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.view];
    //NSMenu *menu = [[NSMenu alloc] initWithTitle:]
    /*NSMenu *menu = [self.delegate menuForCollectionItemView:self];
    [menu popUpMenuPositioningItem:[[menu itemArray] objectAtIndex:0]
                        atLocation:NSZeroPoint
                            inView:self];*/
}

-(CALayer *)borderLayer
{
    if(_borderLayer != nil) return _borderLayer;
        
    _borderLayer = [CALayer layer];
    
    _borderLayer.borderColor = [[NSColor whiteColor] CGColor];
    _borderLayer.borderWidth = 5;
    
    
    [self.view.layer addSublayer:_borderLayer];

    return _borderLayer;
}

- (id)animationForKey:(NSString *)key
{
    return nil;
}


@end
