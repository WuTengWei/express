#import <UIKit/UIKit.h>
#import "ExpressInfo.h"

@interface ExpressTracesViewController : UITableViewController

@property (strong, nonatomic) ExpressInfo* express;
@property (strong,nonatomic) NSDictionary *expressdict;

@property (nonatomic,assign) BOOL isHistory;

@end
