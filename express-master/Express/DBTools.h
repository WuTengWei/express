//
//  DBTools.h
//  Express
//
//  Created by WTW on 2019/7/9.
//  Copyright © 2019 LeeLom. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DBTools : NSObject

+ (NSArray *)statusesWithParams:(NSDictionary *)params;

+ (void)saveStatuses:(NSArray *)statuses;

@end

NS_ASSUME_NONNULL_END
