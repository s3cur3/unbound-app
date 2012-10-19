#import "PreferencesWindowController.h"
#import "Preferences.h"
#import "AppDelegate.h"
//#import "../Utils/Utils.h"


@implementation PreferencesWindowController

static PreferencesWindowController * instance = nil;

+(PreferencesWindowController *)instance
{
	if (instance == nil) 
		instance = [[PreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
    //[instance updatePathControls];
	return instance;
}

+(void)destroy
{
	//[instance release];
	instance = nil;
}

-(void)updatePathControls
{
    NSString *aSearchString = [[NSUserDefaults standardUserDefaults] objectForKey:@"searchLocationKey"];
    if (aSearchString!=nil){
        NSURL *searchURL = [NSURL fileURLWithPath:aSearchString isDirectory:YES];
        [photoPathControl setURL:searchURL];
    }
}

-(void)awakeFromNib
{
    [self updatePathControls];
}

-(id)init
{
	self = [super init];
	if (self != nil)
	{
	}
	return self;
}

-(void)runModal
{
	[NSApp runModalForWindow:[self window]];
	[self close];
}

-(IBAction)handleOK:(id)sender
{
	if ([NSColorPanel sharedColorPanelExists])
		[[NSColorPanel sharedColorPanel] close];
	[NSApp stopModal];
}

-(IBAction)showColorPanel:(id)sender
{
	[NSApp orderFrontColorPanel:sender];
}

-(IBAction)resetToDefaults:(id)sender
{
	[[Preferences instance] resetToDefaults];
}

// -------------------------------------------------------------------------------
//	willDisplayOpenPanel:openPanel:
//
//	Delegate method to NSPathControl to determine how the NSOpenPanel will look/behave.
// -------------------------------------------------------------------------------
- (void)pathControl:(NSPathControl *)pathControl willDisplayOpenPanel:(NSOpenPanel *)openPanel {
    
    // customize the open panel to choose directories
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setMessage:@"Choose a location to search for photos and images:"];
    [openPanel setCanChooseDirectories:YES];
    [openPanel setCanChooseFiles:NO];
    [openPanel setPrompt:@"Choose"];
    [openPanel setTitle:@"Choose Location"];
    
    // set the default location to the Documents folder
    //NSArray *documentsFolderPath = NSSearchPathForDirectoriesInDomains(NSUserDirectory, NSUserDomainMask, YES);
    //[openPanel setDirectoryURL:[NSURL fileURLWithPath:[documentsFolderPath objectAtIndex:0]]];
}

//NSFilePathControl calls this when user selects a new root directory
- (IBAction)photosPathChanged:(id)sender {
    
    //NSURL *oldSearchURL = self.searchLocation;
    NSURL *newURL = (NSURL *)[sender URL];
    AppDelegate *appDelegate = [AppDelegate applicationDelegate];
    [appDelegate updatePhotoSearchURL:newURL];
    //[self updateRootSearchPath:newURL];
    DLog(@"%@", newURL);
}

@end
