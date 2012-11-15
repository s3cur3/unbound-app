//
//  CollectionViewItem.m
//  Unbound
//
//  Created by Bob on 11/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "CollectionViewItem.h"

@interface CollectionViewItem ()

@end

@implementation CollectionViewItem

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)doubleClick:(id)sender {
	NSLog(@"double click in the collectionItem");
	if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
		[[[self collectionView] delegate] performSelector:@selector(doubleClick:) withObject:self];
	}
}

- (id)animationForKey:(NSString *)key
{
    return nil;
}


@end
