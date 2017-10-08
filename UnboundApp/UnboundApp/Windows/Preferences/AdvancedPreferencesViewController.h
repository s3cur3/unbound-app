//
// This is a sample Advanced preference pane
//

#import "MASPreferencesViewController.h"

@interface AdvancedPreferencesViewController : NSViewController <MASPreferencesViewController> {

}

@property (nonatomic, strong) IBOutlet NSTextField *textField;
@property (assign) IBOutlet NSTableView *tableView;

@end
