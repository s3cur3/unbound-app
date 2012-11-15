//
//  AlbumCollectionView.m
//  Unbound
//
//  Created by Bob on 11/7/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "AlbumCollectionView.h"

@implementation AlbumCollectionView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
    [[self enclosingScrollView] setBackgroundColor:color];
    
    // WARNING, THIS IS A PRIVATE METHOD
    [self setValue:@(0) forKey:@"_animationDuration"];
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    /*NSColor * color = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
    [color setFill];
    NSRectFill(dirtyRect);*/
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes
{
    [super setSelectionIndexes:indexes];

}

- (id)animationForKey:(NSString *)key
{
    return nil;
}



@end
