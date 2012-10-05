#import <Cocoa/Cocoa.h>


/**
	Controller used to interact with the preferences panel. It also act as the
	class to manage preferences (setting their default values, etc.)
*/
@interface PreferencesWindowController
	: NSWindowController
{
}

+(PreferencesWindowController *)instance;
+(void)destroy;
-(void)runModal;

-(IBAction)handleOK:(id)sender;
-(IBAction)resetToDefaults:(id)sender;
-(IBAction)showColorPanel:(id)sender;

@end
