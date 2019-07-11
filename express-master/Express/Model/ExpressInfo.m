

#import "ExpressInfo.h"

@implementation ExpressInfo

-(ExpressInfo*)initWitfShipperCode:(NSString *)shipperCode
                   andlogisticCode:(NSString *)logisticCode
                  andexpressTraces:(NSMutableArray *)expressTraces{
    self = [super init];
    if (self) {
        self.shipperCode = shipperCode;
        self.logisticCode = logisticCode;
        self.expressTraces = expressTraces;
    }
    return self;
}
@end
