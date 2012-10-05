#import "PreferencesWindowController.h"
#import "Preferences.h"
//#import "../Utils/Utils.h"


@implementation PreferencesWindowController

static PreferencesWindowController * instance = nil;

+(PreferencesWindowController *)instance
{
	if (instance == nil)
		instance = [[PreferencesWindowController alloc] initWithWindowNibName:@"Preferences"];
	return instance;
}

+(void)destroy
{
	//[instance release];
	instance = nil;
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

@end
