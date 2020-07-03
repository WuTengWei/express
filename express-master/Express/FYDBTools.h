
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FYDBTools : NSObject

+ (NSArray *)statusesWithParams:(NSDictionary *)params;

+ (void)saveStatuses:(NSArray *)statuses;

@end

NS_ASSUME_NONNULL_END
