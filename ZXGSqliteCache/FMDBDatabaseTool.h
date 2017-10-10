
//
//  FMDBDatabaseTool.h
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import <Foundation/Foundation.h>
@class FMDatabaseQueue;
#import "FMDB.h"

@interface FMDBDatabaseTool : NSObject

/**
 *  线程安全数据库
 */
@property(nonatomic,strong,readonly)FMDatabaseQueue *dbQueue;
/**
 *  获取数据库路径
 *
 *  @return 数据库路径
 */
+ (NSString *)databasePath;
/**
 *  单例
 */
+ (instancetype)shareFMDBGetDatabaseTool;

@end

