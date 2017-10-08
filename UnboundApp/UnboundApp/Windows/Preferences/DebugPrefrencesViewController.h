
//
// This is a sample General preference pane
//

#import "MASPreferencesViewController.h"

@interface DebugPrefrencesViewController : NSViewController <MASPreferencesViewController>
{

}

-(IBAction)clearDB:(id)sender;

-(IBAction)scanFullDirectoryStructure:(id)sender;

@property (strong) IBOutlet NSProgressIndicator * workingSpinner;

@end
