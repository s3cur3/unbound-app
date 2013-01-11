//
//  PIXAlbumColllectionView.m
//  UnboundApp
//
//  Created by Bob on 12/14/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumCollectionView.h"
#import <QuartzCore/QuartzCore.h>

@implementation PIXAlbumCollectionView

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
    //[self setValue:@(0) forKey:@"_animationDuration"];
}

- (void)setContent:(NSArray *)content
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue
                     forKey:kCATransactionDisableActions];
    
    [super setContent:content];
    
    [CATransaction commit];
    
}


- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes
{
    [super setSelectionIndexes:indexes];
    
}



@end
