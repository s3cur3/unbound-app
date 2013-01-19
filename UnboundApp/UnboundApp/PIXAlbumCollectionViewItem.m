//
//  PIXAlbumCollectionViewItem.m
//  UnboundApp
//
//  Created by Bob on 12/13/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumCollectionViewItem.h"
#import "PIXBorderedImageView.h"
//#import "Album.h"
#import "PIXDefines.h"

@interface PIXAlbumCollectionViewItem ()
{
    bool isSelected;
}
@end

@implementation PIXAlbumCollectionViewItem

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
    
    
    [self.albumImageView.layer setZPosition:3];
    [self.stackPhoto1.layer setZPosition:2];
    [self.stackPhoto2.layer setZPosition:1];
    [self.stackPhoto3.layer setZPosition:0];
    
    
    
    self.stackPhoto1.image = [NSImage imageNamed:@"temp"];
    self.stackPhoto2.image = [NSImage imageNamed:@"temp-portrait"];
    self.stackPhoto3.image = [NSImage imageNamed:@"temp"];
    
    
    /*CGPoint center = CGPointMake(self.stackPhoto1.bounds.size.width/2, self.stackPhoto1.bounds.size.height/2);
    CGPoint rotatedPoint = CGPointZero;*/
    
    /*
     rotatedPoint = CGPointApplyAffineTransform(center, CGAffineTransformMakeRotation(45));
     [self.stackPhoto1 setf:NSMakePoint(self.stackPhoto1.frame.origin.x + (rotatedPoint.x-center.x),
     self.stackPhoto1.frame.origin.y + (rotatedPoint.y-center.y))];*/
    //[self.stackPhoto1 setFrameCenterRotation:45];
    
    
    
    
    //[self.stackPhoto2 setFrameCenterRotation:45];
    //[self.stackPhoto3 setFrameCenterRotation:-6];*/
    
    
}

-(void)setRepresentedObject:(id)newRepresentedObject
{
    [super setRepresentedObject:newRepresentedObject];
}

/*-(void)setRepresentedObject_new:(id)newRepresentedObject
{
    id oldRepresentedObject = [super representedObject];
    if (oldRepresentedObject == newRepresentedObject) {
        return;
    }
    if ( oldRepresentedObject!=nil ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumDidChangeNotification object:oldRepresentedObject];
    }
    
    [super setRepresentedObject:newRepresentedObject];
    [self.detailLabel setStringValue:[newRepresentedObject imageSubtitle]];
    
    if (newRepresentedObject!=nil) {
        [[NSNotificationCenter defaultCenter] addObserverForName:AlbumDidChangeNotification object:newRepresentedObject queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
            [self.detailLabel setStringValue:[note.object imageSubtitle]];
        }];
    }
    
}*/

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self.albumImageView setSelected:selected];
}


- (void)doubleClick:(NSEvent *)event {
	NSLog(@"double click in the collectionItem");
	if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
		[[[self collectionView] delegate] performSelector:@selector(doubleClick:) withObject:self];
	}
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"rightMouseDown:%@", theEvent);
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Options"];
    NSMenuItem *aMenuItem = [[NSMenuItem alloc] initWithTitle:@"Delete" action:@selector(deleteItem:) keyEquivalent:@""];
    
    //[aMenuItem setTarget:[self.collectionView delegate]];
    
    [theMenu addItem:aMenuItem];
    //[theMenu insertItemWithTitle:@"Delete" action:@selector(deleteItem:) keyEquivalent:@"" atIndex:0];
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.view];
    //NSMenu *menu = [[NSMenu alloc] initWithTitle:]
    /*NSMenu *menu = [self.delegate menuForCollectionItemView:self];
     [menu popUpMenuPositioningItem:[[menu itemArray] objectAtIndex:0]
     atLocation:NSZeroPoint
     inView:self];*/
}



- (id)animationForKey:(NSString *)key
{
    return nil;
}

- (IBAction)textTitleChanged:(id)sender {
    DLog(@"textTitleChanged");
    
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self.mainLabel setBackgroundColor:[NSColor whiteColor]];
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    [self.mainLabel setBackgroundColor:[NSColor whiteColor]];
}


@end
