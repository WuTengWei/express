//
//  DBTools.m
//  Express
//
//  Created by WTW on 2019/7/9.
//  Copyright © 2019 LeeLom. All rights reserved.
//

#import "DBTools.h"
#import "FMDB.h"

@implementation DBTools

static FMDatabase *_db;
+ (void)initialize
{
   
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"tracks.sqlite"];
    _db = [FMDatabase databaseWithPath:path];
    [_db open];
    
    [_db executeUpdate:@"CREATE TABLE IF NOT EXISTS t_tracks (id integer PRIMARY KEY, track blob NOT NULL, idstr text NOT NULL);"];
}

+ (NSArray *)statusesWithParams:(NSDictionary *)params{
    NSString *sql =  @"SELECT * FROM t_tracks ORDER BY idstr DESC ";

    FMResultSet *set = [_db executeQuery:sql];
    NSMutableArray *statuses = [NSMutableArray array];
    while (set.next) {
        NSData *statusData = [set objectForColumnName:@"track"];
        NSDictionary *status = [NSKeyedUnarchiver unarchiveObjectWithData:statusData];
        [statuses addObject:status];
    }
    return statuses;
}

+ (void)saveStatuses:(NSArray *)statuses {
    for (NSDictionary *express in statuses) {
        // NSDictionary --> NSData
        NSData *statusData = [NSKeyedArchiver archivedDataWithRootObject:express];
        [_db executeUpdateWithFormat:@"INSERT INTO t_tracks(track, idstr) VALUES (%@, %@);", statusData, express[@"LogisticCode"]];
    }
    
}


@end
