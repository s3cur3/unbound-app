//
// This is a sample General preference pane
//

#import "MASPreferencesViewController.h"

@interface GeneralPreferencesViewController : NSViewController <MASPreferencesViewController>

-(IBAction)themeChanged:(id)sender;
- (IBAction)chooseFolder:(id)sender;
- (IBAction)reloadFiles:(id)sender;

@end
