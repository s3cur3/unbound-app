//
//  PIXAboutWindowController.m
//  UnboundApp
//
//  Created by Scott Sykora on 4/13/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAboutWindowController.h"

@interface PIXAboutWindowController ()

@property (retain) IBOutlet NSTextField * titleField;

@end

@implementation PIXAboutWindowController

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    NSString *version =[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    
    self.titleField.stringValue = [NSString stringWithFormat:@"Unbound v. %@", version];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

-(IBAction)unboundLearnMore:(id)sender
{
    NSURL * url = [NSURL URLWithString:@"http://www.pixiteapps.com"];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

@end
