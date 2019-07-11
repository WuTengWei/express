
/*
 用来保存从网络上请求成功后返回的数据
 */
#import <Foundation/Foundation.h>

@interface ExpressInfo : NSObject

@property (strong, nonatomic) NSString* shipperCode;//快递名称
@property (strong, nonatomic) NSString* logisticCode;//快递单号
@property (strong ,nonatomic) NSMutableArray* expressTraces;//快递轨迹

- (ExpressInfo *)initWitfShipperCode:(NSString*)shipperCode
                    andlogisticCode:(NSString *)logisticCode
                   andexpressTraces:(NSMutableArray *)expressTraces;
@end
