//
//  PIXPageControlView.m
//  UnboundApp
//
//  Created by Scott Sykora on 3/17/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPageHUDView.h"
#import "PIXPageHUDWindow.h"
#import "PIXPhoto.h"

@interface PIXPageHUDView () <NSTextViewDelegate>

@property (strong) NSTrackingArea * boundsTrackingArea;

@property (strong) IBOutlet NSScrollView * captionScrollView;
@property (strong) IBOutlet NSTextView * captionTextView;

@property (strong) IBOutlet NSView * buttonHolderView;

@property (strong) IBOutlet NSLayoutConstraint * topCaptionSpace;
@property (strong) IBOutlet NSLayoutConstraint * bottomCaptionSpace;

@property (strong) NSArray * topCaptionConstraints;
@property (strong) NSArray * bottomCaptionConstraints;

@property (strong) NSArray * captionConstraints;


@property (nonatomic) BOOL captionEditCancelled;

@property (nonatomic) BOOL isShowingCaption;
@property (nonatomic) BOOL mouseDragged;

@end

@implementation PIXPageHUDView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)mouseEntered:(NSEvent *)theEvent
{
    [(PIXPageHUDWindow *)[self window] setHasMouse:YES];
}

-(void)mouseMoved:(NSEvent *)theEvent
{
    [(PIXPageHUDWindow *)[self window] setHasMouse:YES];
}


-(void)mouseExited:(NSEvent *)theEvent
{
    [(PIXPageHUDWindow *)[self window] setHasMouse:NO];
}

-(void)updateTrackingAreas
{
    
    if(self.boundsTrackingArea != nil) {
        [self removeTrackingArea:self.boundsTrackingArea];
    }
    
    int opts = (NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways | NSTrackingMouseMoved);
    self.boundsTrackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                            options:opts
                                                              owner:self
                                                           userInfo:nil];
    [self addTrackingArea:self.boundsTrackingArea];
}

-(void)setPhoto:(PIXPhoto *)photo
{
    _photo = photo;
    [self setupCaptionSpace];
    
}

#pragma mark -
#pragma mark caption display

-(void)setupCaptionSpace
{
    float newSpace = 0;
    if(([self.photo caption] != nil && ![[self.photo caption] isEqualToString:@""]) ||
       [self isTextEditing])
    {
        self.isShowingCaption = YES; // this will add the view to the subview if needed
        
        if(self.photo.caption)
        {
            [self.captionTextView setString:self.photo.caption];
        }
        
        else
        {
            [self.captionTextView setString:@""];
        }
        
        
        // find the height the text view should be:
        
        [[self.captionTextView textStorage] setFont:[NSFont fontWithName:@"Helvetica" size:18]];
        [[self.captionTextView textStorage] setForegroundColor:[NSColor whiteColor]];
        [[self.captionTextView textStorage] setAlignment:NSCenterTextAlignment range:NSMakeRange(0, [self.captionTextView textStorage].length)];
        
        NSTextStorage *textStorage = [[NSTextStorage alloc] initWithAttributedString:self.captionTextView.attributedString];
        NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(self.captionTextView.frame.size.width, FLT_MAX)];
        [layoutManager addTextContainer:textContainer];
        [textStorage addLayoutManager:layoutManager];

        // NSLayoutManager is lazy, so we need the following kludge to force layout:
		[layoutManager glyphRangeForTextContainer:textContainer];
        
        CGRect usedRect = [layoutManager usedRectForTextContainer:textContainer];
        
        //NSRect boundingRect = [self.captionTextView.attributedString boundingRectWithSize:NSMakeSize(self.captionTextView.frame.size.width, 10000) options:nil];
        
        //CGFloat height = boundingRect.size.height + 15;
        
        newSpace = usedRect.size.height + 15;
        
        // max the space out at 100px (the scrollview will scroll
        if(newSpace > 150) newSpace = 150;
        
        // if we're textediting then always have at least 80px
        if(self.isTextEditing && newSpace < 80) newSpace = 80;
        
        [self.captionTextView setNeedsDisplay:YES];
        
        //[self.captionTextView setFont:[NSFont fontWithName:@"Helvetica" size:11] range:NSMakeRange(0,[self.photo.caption length])];
        [self.captionTextView setEditable:NO];
        [self.captionTextView setSelectable:NO];
    }
    
    else
    {
        self.isShowingCaption = NO;
        
        newSpace = 15;
    }
    
    CGRect windowFrame = self.window.frame;
    
    CGFloat newHeight = 55 + newSpace;
    
    if(newHeight > windowFrame.size.height)
    {
        windowFrame.size.height = newHeight;
        
        if(self.captionIsBelow)
        {
            windowFrame.origin.y -= (newHeight - windowFrame.size.height);
        }
        
        [(PIXPageHUDWindow *)self.window positionWindowWithSize:windowFrame.size animated:NO];
        //[self.window setFrame:windowFrame display:YES animate:NO];
        //[(PIXPageHUDWindow *)self.window setPositionAnimated:NO];
    }
    
    
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
        // Start the animations.
        
        if(self.captionIsBelow)
        {
            [self.bottomCaptionSpace.animator setConstant:newSpace];
            [self.topCaptionSpace.animator setConstant:15];
        }
        
        else
        {
            [self.bottomCaptionSpace.animator setConstant:15];
            [self.topCaptionSpace.animator setConstant:newSpace];
        }
        
    } completionHandler:^{}];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fixCaptionSpace) object:nil];
    [self performSelector:@selector(fixCaptionSpace) withObject:nil afterDelay:0.5];

}

-(void)fixCaptionSpace
{
    CGFloat newHeight = 55;
    
    if(self.captionIsBelow)
    {
        newHeight += self.bottomCaptionSpace.constant;
    
    }
    
    else
    {
        newHeight += self.topCaptionSpace.constant;
    }
    // this method will be called wheån the animations called above have been completed
    
    
    CGRect newWindowFrame = self.window.frame;
    newWindowFrame.size.height = newHeight;
    
    if(self.captionIsBelow)
    {
        newWindowFrame.origin.y -= (newHeight - newWindowFrame.size.height);
    }
    
    // update the window if it's in a different place
    if(!CGRectEqualToRect(self.window.frame, newWindowFrame))
    {
        [(PIXPageHUDWindow *)self.window positionWindowWithSize:newWindowFrame.size animated:NO];
    }
    //[self.window setFrame:newWindowFrame display:YES animate:NO];
}

-(void)setIsShowingCaption:(BOOL)isShowingCaption
{
    if(isShowingCaption != _isShowingCaption)
    {
        _isShowingCaption = isShowingCaption;
        
        if(self.captionConstraints)
        {
            [self removeConstraints:self.captionConstraints];
            self.captionConstraints = nil;
        }
        
        if(_isShowingCaption)
        {
        
            
            
            //[self setTranslatesAutoresizingMaskIntoConstraints:YES];
            [self.captionScrollView setTranslatesAutoresizingMaskIntoConstraints:YES];
            
            [self addSubview:self.captionScrollView];
        }
        
        else
        {
            [self.captionScrollView removeFromSuperview];
        }
            
            
            
    }
        
    // always set the caption frame if it's showing
    if(isShowingCaption)
    {
        CGRect textFrame = self.bounds;
        
        textFrame = CGRectInset(textFrame, 15, 15);
        
        textFrame.size.height -= 38;
        
        if(!self.captionIsBelow)
        {
            textFrame.origin.y += 38;
        }
        
        [self.captionScrollView setAutoresizingMask:0];
        
        [self.captionScrollView setFrame:textFrame];
        
        [self.captionScrollView setAutoresizingMask:(NSViewWidthSizable |
                                                     NSViewHeightSizable)];
        
        [self.captionTextView scrollPoint:NSZeroPoint];
        
        [self.captionTextView setFrame:self.captionScrollView.bounds];
        [self.captionScrollView setNeedsDisplay:YES];
    }
}

-(void)setCaptionIsBelow:(BOOL)captionIsBelow
{
    if(captionIsBelow != _captionIsBelow)
    {
        _captionIsBelow = captionIsBelow;
        
        
        // change the constraints so the view sticks to the top or bottom correctly
        
        [self.superview removeConstraints:self.superview.constraints];
        
        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(self);
        
        NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[self]-0-|"
                                                                                 options:0
                                                                                 metrics:nil
                                                                                   views:viewsDictionary];
        
        [self.superview addConstraints:horizontalConstraints];
        
        if(captionIsBelow)
        {
            
            
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[self]->=0-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:viewsDictionary];
            
            
            [self.superview addConstraints:constraints];
            
        }
        
        else
        {
            
            NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(self);
            NSArray *constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|->=0-[self]-0-|"
                                                                           options:0
                                                                           metrics:nil
                                                                             views:viewsDictionary];
            
            [self.superview addConstraints:constraints];
        }
        
        
        
        [self setupCaptionSpace];
    }
}

#pragma mark -
#pragma mark caption edit mode handling
-(void)mouseDown:(NSEvent *)theEvent
{
    [super mouseDown:theEvent];
    self.mouseDragged = NO;
}

-(void)mouseUp:(NSEvent *)theEvent
{
    
    if(self.mouseDragged == NO &&
       NSPointInRect([self convertPoint:[theEvent locationInWindow] fromView:nil], self.captionScrollView.frame) &&
       self.isShowingCaption)
    {
        [self startEditingCaption:self];
    }
    
    [super mouseUp:theEvent];
    self.mouseDragged = NO;
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [super mouseDragged:theEvent];
    self.mouseDragged = YES;
}


-(IBAction)toggleCaptionEdit:(id)sender
{
    if(self.isTextEditing)
    {
        [self textDidEndEditing:sender];
    }
    
    else
    {
        [self startEditingCaption:self];
    }
}

-(IBAction)startEditingCaption:(id)sender
{
    [self setIsTextEditing:YES];
    [self setupCaptionSpace];
    
    [(PIXPageHUDWindow *)self.window makeKeyAndOrderFront:sender];
    [self.captionTextView setEditable:YES];
    [self.window makeFirstResponder:self.captionTextView];
    
    [self.captionTextView setDelegate:self];
    
    
    [self.captionTextView setSelectedTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [NSColor colorWithCalibratedWhite:1.0 alpha:0.5], NSBackgroundColorAttributeName,
      [NSColor blackColor], NSForegroundColorAttributeName,
      nil]];
    
    self.captionEditCancelled = NO;
    
}


-(void)cancelOperation:(id)sender
{
    if(self.isTextEditing)
    {
        self.captionEditCancelled = YES;
        [[NSApp mainWindow] makeKeyWindow];
    }
}

-(void)insertNewline:(id)sender
{
    if(self.isTextEditing)
    {
        //self.captionEditCancelled = YES;
        [[NSApp mainWindow] makeKeyWindow];
    }
}


-(void)textDidEndEditing:(NSNotification *)notification
{
    if(self.captionEditCancelled == NO)
    {
        [self.photo userSetCaption:self.captionTextView.string];
    }
    
    else
    {
        if(self.photo.caption)
        {
            [self.captionTextView setString:self.photo.caption];
        }
        
        else
        {
            [self.captionTextView setString:@""];
        }
    }
    
    [self.captionTextView setSelectedRange:NSMakeRange(0, 0)];
    
    [self setIsTextEditing:NO];
    [[NSApp mainWindow] makeKeyWindow];
    
    [self.captionTextView setEditable:NO];
    [self.captionTextView setSelectable:NO];
    
    [self.window makeFirstResponder:self];
    
    [self setupCaptionSpace];
}

- (BOOL)textView:(NSTextView *)aTextView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [[self.captionTextView textStorage] setFont:[NSFont fontWithName:@"Helvetica" size:18]];
        [[self.captionTextView textStorage] setForegroundColor:[NSColor whiteColor]];
        [[self.captionTextView textStorage] setAlignment:NSCenterTextAlignment range:NSMakeRange(0, [self.captionTextView textStorage].length)];
        [self.captionTextView alignCenter:nil];
    });
    
    // if the user hit return without holding down 
    if([replacementString isEqualToString:@"\n"] && !([NSEvent modifierFlags] & NSShiftKeyMask))
    {
        [[NSApp mainWindow] makeKeyWindow];
        return NO;
    }
    
    return YES;
}

- (NSDictionary *)textView:(NSTextView *)textView shouldChangeTypingAttributes:(NSDictionary *)oldTypingAttributes toAttributes:(NSDictionary *)newTypingAttributes
{
    return newTypingAttributes;
}

/*
- (NSRange)textView:(NSTextView *)aTextView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{
    
    [[self.captionTextView textStorage] setFont:[NSFont fontWithName:@"Helvetica" size:18]];
    [[self.captionTextView textStorage] setForegroundColor:[NSColor whiteColor]];
    [[self.captionTextView textStorage] setAlignment:NSCenterTextAlignment range:NSMakeRange(0, [self.captionTextView textStorage].length)];
    
    
    return newSelectedCharRange;
}*/

#pragma mark -
#pragma mark background drawing

- (void)drawRect:(NSRect)dirtyRect
{
    // Drawing code here.
    
    
    NSRect innerbounds = CGRectInset(self.bounds, 6.0, 6.0);
    NSBezierPath *selectionRectPath = [NSBezierPath bezierPathWithRoundedRect:innerbounds xRadius:10 yRadius:10];
    
    
    // draw a shadow under the round rect
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextSetShadowWithColor(context, CGSizeMake(0, -1), 6.0, [[NSColor colorWithGenericGamma22White:0.0 alpha:.7] CGColor]);
    
    // fill the round rect
    [[NSColor colorWithCalibratedWhite:0.0 alpha:.5] setFill];
    [selectionRectPath fill];
    
    // turn off the shadow
    CGContextSetShadowWithColor(context, CGSizeZero, 0, NULL);
    
    // stroke the outside
    [[NSColor colorWithCalibratedWhite:1.0 alpha:.3] setStroke];
    [selectionRectPath setLineWidth:2.0];
    [selectionRectPath stroke];
}




@end
