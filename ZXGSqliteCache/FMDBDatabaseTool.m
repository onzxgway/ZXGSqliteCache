//
//  FMDBDatabaseTool.m
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import "FMDBDatabaseTool.h"

@implementation FMDBDatabaseTool
@synthesize dbQueue = _dbQueue;

//单例
+ (instancetype)shareFMDBGetDatabaseTool {
    static FMDBDatabaseTool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

//获取数据库路径
+ (NSString *)databasePath {
    
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"HKLDB"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir;
    BOOL isExists = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (!isExists || !isDir) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    return [path stringByAppendingPathComponent:@"hkldb.sqlite"];
}

//创建多线程安全的数据库
- (FMDatabaseQueue *)dbQueue
{
    if (_dbQueue == nil) {
        _dbQueue = [[FMDatabaseQueue alloc] initWithPath:[[self class] databasePath]];
    }
    return _dbQueue;
}

@end
