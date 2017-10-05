//
//  PIXAlbumCollectionViewItem.m
//  UnboundApp
//
//  Created by Ditriol Wei on 3/8/16.
//  Copyright © 2016 Pixite Apps LLC. All rights reserved.
//

#import "PIXAlbumCollectionViewItem.h"
#import "PIXAlbum.h"
#import "PIXPhoto.h"
#import <QuartzCore/QuartzCore.h>
#import "PIXDefines.h"
#import "PIXFileManager.h"
#import "PIXViewController.h"
#include <stdlib.h>

@implementation PIXAlbumCollectionViewItem

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do view setup here.
}

- (void)setRepresentedObject:(id)obj
{
    PIXAlbumCollectionViewItemView * view = (PIXAlbumCollectionViewItemView *)self.view;
    view.album = obj;
}

- (id)representedObject
{
    PIXAlbumCollectionViewItemView * view = (PIXAlbumCollectionViewItemView *)self.view;
    return view.album;
}

- (void)setSelected:(BOOL)s
{
    NSLog(@"Selected: %d", s);
    PIXAlbumCollectionViewItemView * view = (PIXAlbumCollectionViewItemView *)self.view;
    view.selected = s;
    if( view.album != nil )
        [view setNeedsDisplay:YES];
}

- (BOOL)isSelected
{
    PIXAlbumCollectionViewItemView * view = (PIXAlbumCollectionViewItemView *)self.view;
    return view.selected;
}

@end


@interface PIXAlbumCollectionViewItemView () <NSTextFieldDelegate>
@property (strong, nonatomic) IBOutlet NSTextField *mainLabel;
@property (strong) NSOrderedSet * loadingPhotos;
@property (strong, nonatomic) NSImage * albumThumb;
@property (strong, nonatomic) NSImage * stackThumb1;
@property (strong, nonatomic) NSImage * stackThumb2;
@property (strong, nonatomic) NSImage * stackThumb3;

@property CGFloat stackThumb1Rotate;
@property CGFloat stackThumb2Rotate;

@property BOOL isDraggingOver;
@property BOOL topLevelThumbIsVideo;

@property CGRect titleEditFrame;
@property (strong) NSTextField * titleEditField;
@property BOOL allowTitleEdit;
@end

@implementation PIXAlbumCollectionViewItemView

+ (NSImage *)dragImageForAlbums:(NSArray *)albumArray size:(NSSize)size
{
    if([albumArray count] == 0) return [NSImage imageNamed:@"nophoto"];
    
    PIXAlbum * topAlbum = [albumArray objectAtIndex:0];
    
    
    // set up the images
    NSImage * image1 = nil;
    NSImage * image2 = nil;
    NSImage * image3 = nil;
    
    if([[topAlbum stackPhotos] count])
    {
        image1 = [[[topAlbum stackPhotos] objectAtIndex:0] thumbnailImage]; // load this one at a higher priority
        
        if([[topAlbum stackPhotos] count] > 1)
        {
            image2 = [[[topAlbum stackPhotos] objectAtIndex:1] thumbnailImage];
            
            if([[topAlbum stackPhotos] count] > 2)
            {
                image3 = [[[topAlbum stackPhotos] objectAtIndex:2] thumbnailImage];
            }
        }
    }
    
    if(image1 == nil)
    {
        image1 =[NSImage imageNamed:@"temp"];
    }
    
    if(image2 == nil)
    {
        image2 =[NSImage imageNamed:@"temp-portrait"];
    }
    
    if(image3 == nil)
    {
        image3 =[NSImage imageNamed:@"temp"];
    }
    
    NSString * title = [topAlbum title];
    
    // set up the title
    if([albumArray count] > 1)
    {
        title = [NSString stringWithFormat:@"%ld Albums", [albumArray count]];
    }
    
    return [self dragStackForImages:@[image1, image2, image3] size:size title:title andBadgeCount:[albumArray count]];
}


- (id)init
{
    self = [super init];
    if (self) {
        
        self.stackThumb1 = [NSImage imageNamed:@"temp"];
        self.stackThumb2 = [NSImage imageNamed:@"temp-portrait"];
        
        [self registerForDraggedTypes:[NSArray arrayWithObject: NSURLPboardType]];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender
{
    // for now don't accept drags from our own app (this will be used for merging albums later)
    if([sender draggingSource] != nil)
    {
        return NSDragOperationNone;
    }
    NSArray *pathsToPaste = [[PIXFileManager sharedInstance] itemsForDraggingInfo:sender forDestination:self.album.path];
    NSUInteger fileCount = [pathsToPaste count];
    sender.numberOfValidItemsForDrop = fileCount;
    if (fileCount==0) {
        return NSDragOperationNone;
    }
    
    self.isDraggingOver = YES;
    [self setNeedsDisplay:YES];
    
    if([sender draggingSource] == nil)
    {
        return NSDragOperationCopy;
    }
    
    return NSDragOperationMove;
}

- (void)draggingExited:(id < NSDraggingInfo >)sender
{
    self.isDraggingOver = NO;
    [self setNeedsDisplay:YES];
}

- (void)draggingEnded:(id < NSDraggingInfo >)sender
{
    self.isDraggingOver = NO;
    [self setNeedsDisplay:YES];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    // for now don't accept drags from our own app (this will be used for re-ordering photos later)
    if([sender draggingSource] != nil)
    {
        return NO;
    }
    if(sender.numberOfValidItemsForDrop == 0)
    {
        return NO;
    }
    
    NSArray *pathsToPaste = [[PIXFileManager sharedInstance] itemsForDraggingInfo:sender forDestination:self.album.path];
    
    if ([PIXViewController optionKeyIsPressed])
    {
        [[PIXFileManager sharedInstance] moveFiles:pathsToPaste];
    } else {
        [[PIXFileManager sharedInstance] copyFiles:pathsToPaste];
    }
    return YES;
    
    
}

- (void)setAlbum:(PIXAlbum *)album
{
    //NSAssert(album!=nil, @"Unexpected setting of album to nil in PIXAlbuGridViewItem.");
    
    // only set it if it's different
    if(_album != album)
    {
        self.topLevelThumbIsVideo = NO;
        
        // stop watching for old album updates
        if (_album != nil)
        {
            [self cancelThumbnailLoading];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AlbumStackDidChangeNotification object:_album];
        }
        
        _album = album;
        
        // start watching for new album updates
        if(_album != nil)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(albumChanged:) name:AlbumStackDidChangeNotification object:_album];
        }
        
        [self albumChanged:nil];
        
        // randomly rotate thumbs based on album name (so it won't change on refresh)
        int random = 0;
        
        // add the value of each character together
        for (int position=0; position < [album.title length]; position++)
        {
            random += (int)[album.title characterAtIndex:position];
        }
        
        // randomly rotate the first between -.05 and .05
        self.stackThumb1Rotate = (CGFloat)(random % 140)/1000 - .07;
        
        // the second needs to be the difference so that we rotate the object back
        self.stackThumb2Rotate = (CGFloat)(random % 183)/1300 - .07 - self.stackThumb1Rotate;
        
        
        
        //[self displayIfNeeded];
        
        
    }
}


- (void)albumChanged:(NSNotification *)note
{
    if([self.album isReallyDeleted]) return;
    
    [self setItemTitle:[self.album title]];
    
    
    //self.topLevelThumbIsVideo = NO;
    
    
    self.albumThumb = nil;
    self.loadingPhotos = [self.album stackPhotos];
    
    // if we've got one stack photo
    if([[self.album stackPhotos] count] > 0)
    {
        
        PIXPhoto * thumbPhoto = [[self.album stackPhotos] objectAtIndex:0];
        //[thumbPhoto setStackPhotoAlbum:self.album];
        
        NSImage * newThumb = [thumbPhoto thumbnailImageFast];
        
        if(newThumb)
        {
            self.albumThumb = newThumb;
            if ([thumbPhoto isVideo]) {
                self.topLevelThumbIsVideo = YES;
            } else {
                self.topLevelThumbIsVideo = NO;
            }
        }
        
        // we'll check for a nil photo outside of this if because albums with no photos should still have one placeholder thumb
        
        
        // if we have two stack photos get both
        if([[self.album stackPhotos] count] > 1)
        {
            PIXPhoto * thumbPhoto2 = [[self.album stackPhotos] objectAtIndex:1];
            //[thumbPhoto2 setStackPhotoAlbum:self.album];
            
            self.stackThumb1 = [thumbPhoto2 thumbnailImage];
            
            if(self.stackThumb1 == nil)
            {
                self.stackThumb1 = [NSImage imageNamed:@"temp-portrait"];
            }
            
            // if we have three stack photos get all three
            if([[self.album stackPhotos] count] > 2)
            {
                PIXPhoto * thumbPhoto3 = [[self.album stackPhotos] objectAtIndex:2];
                //[thumbPhoto3 setStackPhotoAlbum:self.album];
                
                self.stackThumb2 = [thumbPhoto3 thumbnailImage];
                
                if(self.stackThumb2 == nil)
                {
                    self.stackThumb2 = [NSImage imageNamed:@"temp"];
                }
            }
            
            else
            {
                self.stackThumb2 = nil; // we don't have three photos, don't draw the third
            }
            
            
        }
        
        else
        {
            self.stackThumb1 = nil; // we don't have two photos, don't draw the second or third
            self.stackThumb2 = nil;
        }
    }
    
    else
    {
        self.stackThumb1 = nil; // we don't have two photos, don't draw the second or third
        self.stackThumb2 = nil;
    }
    
    if(self.albumThumb == nil)
    {
        self.albumThumb = [NSImage imageNamed:@"temp"];
    }
    
    
    
    
    [self setNeedsDisplay:YES];
}

-(BOOL)isOpaque
{
    return YES;
}

- (void)drawRect:(NSRect)rect
{
    NSRect bounds = self.bounds;
    
    NSBezierPath *contentRectPath = [NSBezierPath bezierPathWithRect:rect];
    
    NSColor * textColor = nil;
    NSColor * subtitleColor = nil;
    NSColor * bgColor = nil;
    
    if([[NSUserDefaults standardUserDefaults] integerForKey:@"backgroundTheme"] == 0)
    {
        bgColor = [NSColor colorWithCalibratedWhite:0.912 alpha:1.000];
        textColor = [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
        subtitleColor = [NSColor colorWithCalibratedWhite:0.35 alpha:1.0];
    }
    
    else
    {
        bgColor = [NSColor colorWithPatternImage:[NSImage imageNamed:@"dark_bg"]];
        textColor = [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
        subtitleColor = [NSColor colorWithCalibratedWhite:0.55 alpha:1.0];
    }

    [bgColor setFill];
    [contentRectPath fill];
    
    // draw dragging hover state
    if (self.isDraggingOver) {
        
        NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
        NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
        [[NSColor colorWithCalibratedWhite:.5 alpha:.2] setFill];
        [selectionRectPath fill];
    }
    
    
    /// draw selection ring
    if (self.selected) {
        
        NSRect innerbounds = CGRectInset(self.bounds, 6, 6);
        NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
        [[NSColor colorWithCalibratedRed:0.189 green:0.657 blue:0.859 alpha:1.000] setStroke];
        [selectionRectPath setLineWidth:4];
        [selectionRectPath stroke];
    }
    
    
    NSRect srcRect = NSZeroRect;
    srcRect.size = self.itemImage.size;
    
    NSRect textRect = NSMakeRect(bounds.origin.x + 13,
                                 NSHeight(bounds) - 50,
                                 NSWidth(bounds) - 26,
                                 20);
    
    NSRect subTitleRect = NSMakeRect(bounds.origin.x + 3,
                                     NSHeight(bounds) - 28,
                                     NSWidth(bounds) - 6,
                                     20);
    
    self.titleEditFrame = NSInsetRect(textRect, -3, -3);
    
    NSShadow *textShadow    = [[NSShadow alloc] init];
    [textShadow setShadowColor: [NSColor colorWithCalibratedWhite:0.0 alpha:0.5]];
    [textShadow setShadowOffset: NSMakeSize(0, -1)];
    
    NSMutableParagraphStyle *textStyle = [[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
    [textStyle setAlignment: NSCenterTextAlignment];
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                 [NSFont fontWithName:@"Helvetica Neue Bold" size:14], NSFontAttributeName,
                                 //                           textShadow,                                 NSShadowAttributeName,
                                 //                           bgColor,                                    NSBackgroundColorAttributeName,
                                 textColor,                                  NSForegroundColorAttributeName,
                                 textStyle,                                  NSParagraphStyleAttributeName,
                                 nil];
    
    
    
    [[self.album title] drawInRect:textRect withAttributes:attributes];
    
    attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSFont fontWithName:@"Helvetica Neue" size:11], NSFontAttributeName,
                  //                           textShadow,                                 NSShadowAttributeName,
                  //                           bgColor,                                    NSBackgroundColorAttributeName,
                  subtitleColor,                                  NSForegroundColorAttributeName,
                  textStyle,                                  NSParagraphStyleAttributeName,
                  nil];
    
    NSString * itemSubtitle = self.album.imageSubtitle;
    
    [itemSubtitle drawInRect:subTitleRect withAttributes:attributes];
    
    
    CGRect albumFrame = CGRectInset(self.bounds, 18, 35);
    albumFrame.origin.y -= 20;
    
    // draw the stack of imagess
    
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    
    CGContextSaveGState(context);
    
    CGContextTranslateCTM(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextRotateCTM(context, self.stackThumb2Rotate);
    CGContextTranslateCTM(context, -self.bounds.size.width/2, -self.bounds.size.height/2);
    
    [[self class] drawBorderedPhoto:self.stackThumb2 inRect:albumFrame];
    
    CGContextTranslateCTM(context, self.bounds.size.width/2, self.bounds.size.height/2);
    CGContextRotateCTM(context, self.stackThumb1Rotate);
    CGContextTranslateCTM(context, -self.bounds.size.width/2, -self.bounds.size.height/2);
    
    [[self class] drawBorderedPhoto:self.stackThumb1 inRect:albumFrame];
    
    CGContextRestoreGState(context);
    
    
    // draw the top image
    CGRect imageFrame = [[self class] drawBorderedPhoto:self.albumThumb inRect:albumFrame];
    //PIXPhoto * thumbPhoto = [[self.album stackPhotos] objectAtIndex:0];
    if (self.topLevelThumbIsVideo) {
        CGRect imageRect = CGRectInset(imageFrame, 3, 3);
        //[photo drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
        NSImage *playButtonImage = [NSImage imageNamed:@"playbutton"];
        [playButtonImage setScalesWhenResized:YES];
        CGRect playButtonRect = CGRectMake(CGRectGetMidX(imageRect)-20.0, CGRectGetMidY(imageRect)-20.0, 40.0, 40.0);//CGRectApplyAffineTransform(imageRect, CGAffineTransformMakeScale(0.33, 0.33));
        [playButtonImage drawInRect:playButtonRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0 respectFlipped:YES hints:nil];
    }
    
    
    // include the title area in the contentFrame so clicks there will select the item
    albumFrame.size.height = (textRect.origin.y+textRect.size.height) - albumFrame.origin.y;
    self.contentFrame = albumFrame;
    
}

-(void)startEditing
{
    if(self.titleEditField == nil)
    {
        self.titleEditField = [[NSTextField alloc] initWithFrame:self.titleEditFrame];
        self.titleEditField.delegate = self;
        self.titleEditField.stringValue = [self.album title];
        
        [self.titleEditField setFont:[NSFont fontWithName:@"Helvetica Neue Bold" size:14]];
        [self.titleEditField setAlignment:NSCenterTextAlignment];
        
        [self.titleEditField setTarget:self];
        [self.titleEditField setAction:@selector(titleEdited:)];
        [(NSTextFieldCell *)self.titleEditField.cell setSendsActionOnEndEditing:YES];
        
        [self addSubview:self.titleEditField];
        
        [self.window makeFirstResponder:self.titleEditField];
    }
}

-(void)titleEdited:(id)sender
{
    DLog(@"titleEdited");
    
    if([self.album isReallyDeleted]) return;
    
    NSTextField *aTextField =(NSTextField *)sender;
    
    
    if ([aTextField.stringValue length]==0 || [aTextField.stringValue isEqualToString:self.album.title])
    {
        DLog(@"renaming to empty string or same name disallowed.");
        return;
    }
    
    PIXAlbum * thisAlbum = self.album;
    
    BOOL success = [[PIXFileManager sharedInstance] renameAlbum:thisAlbum withName:aTextField.stringValue];
    
    if (!success)
    {
        //an error occurred when moving so keep the old title
        aTextField.stringValue = self.album.title;
        [self performSelector:@selector(startEditing) withObject:self afterDelay:0.0f];
        return;
    } else {
        //[[NSNotificationCenter defaultCenter] postNotificationName:AlbumDidChangeNotification object:anAlbum];
        //DLog(@"Album was renamed successfuly : \"%@\"", self.album.path);
        
        // scroll to this album in the grid view
        [[NSNotificationCenter defaultCenter] postNotificationName:AlbumWasRenamedNotification object:thisAlbum];
        
    }
    
    // update the album
    [self albumChanged:nil];
    
    
    
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    // seem to need to handl
    if (commandSelector == @selector(cancelOperation:)) {
        
        
        [self controlTextDidEndEditing:nil];
        
        return YES;
    }
    
    return NO;
}


-(void)controlTextDidEndEditing:(NSNotification *)obj
{
    if(self.titleEditField != nil)
    {
        // this will stop the action from being sent if we called this from the cancelOperation detection above
        if(obj == nil)
        {
            [self.titleEditField setTarget:nil];
        }
        
        [self.titleEditField removeFromSuperview];
        self.titleEditField = nil;
    }
}

-(void)mouseDown:(NSEvent *)theEvent
{
    if(self.selected) {
        self.allowTitleEdit = YES;
    } else {
        self.allowTitleEdit = NO;
    }
    
    [[self nextResponder] mouseDown:theEvent];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    self.allowTitleEdit = NO;
    [[self nextResponder] mouseDragged:theEvent];
}


-(void)mouseUp:(NSEvent *)theEvent
{
    NSLog(@"PIXAlbumCollectionViewItem: mouseUp");
    // only check for title edits if this was already selected on mouse down
    if(self.allowTitleEdit)
    {
        NSPoint location = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        
        // if the user clicked up in title box
        if(CGRectContainsPoint(self.titleEditFrame, location))
        {
            [self startEditing];
            return;
        }
    }
    [[self nextResponder] mouseUp:theEvent];
}

- (void)prepareForReuse
{
    if (self.album )  {
        
        self.album = nil;
    }
    
    self.stackThumb1 = [NSImage imageNamed:@"temp"];
    self.stackThumb2 = [NSImage imageNamed:@"temp-portrait"];
    self.stackThumb3 = [NSImage imageNamed:@"temp"];
    
    [super prepareForReuse];
    
}

- (void)cancelThumbnailLoading
{
    for(PIXPhoto * photo in self.loadingPhotos)
    {
        [photo cancelThumbnailLoading];
    }
    
    self.loadingPhotos = nil;
}

- (id)representedObject
{
    return self.album;
}

@end