//
//  ZXGFMDBModel.h
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDBDatabaseTool.h"
#import "FMDB.h"

/** SQLite五种数据类型 */
#define SQLTEXT  @"TEXT"
#define SQLINTEGER  @"INTEGER"
#define SQLREAL  @"REAL"
#define SQLBLOB  @"BLOB"
#define SQLNULL  @"NULL"

#define SQLMODEL  @"MODEL"//sqlite没有model这个数据类型，这只是为了与数组进行区分
#define primaryId  @"id"

/*
 使用注意事项：
 1.如果一个数据模型需要进行数据库操作，那么必须继承ZXGFMDBModel；
 2.如果模型类的某个属性类型是一个自定义类，那么该自定义类必须遵从NSCoding协议。
 */
@interface ZXGFMDBModel : NSObject

/** primary key id */
@property (nonatomic, assign)NSInteger id;

/** 字段名数组 */
@property (strong, nonatomic, readonly) NSArray *columnNames;

/** 字段类型数组 */
@property (strong, nonatomic, readonly) NSArray *columnTypes;

#pragma mark -- 创建表
/**
 默认创建的表名是当前的类名
 
 @return YES:创表成功，NO：失败
 */
+ (BOOL)zxg_createTable;

/**
 数据库中是否存在表
 
 @return YES:存在，NO：不存在
 */
+ (BOOL)zxg_isExistInTable;

/**
 使用runtime，获取当前类的所有属性以及属性对应的类型,并且存入字典中
 
 @return 包含属性和属性类型的字典
 */
+ (NSDictionary *)zxg_getPropertys;

#pragma mark -- 插入
/**
 * 插入一条数据
 */
- (BOOL)zxg_insertOne;

/**
 使用事务批量插入
 
 @param array 要插入的数组
 
 @return 是否插入成功
 */
+ (BOOL)zxg_insertArray:(NSArray *)array;

#pragma mark -- 删除
/**
 根据条件删除
 
 @param conditionStr 删除的条件语句 例如：@"where id < 5"
 
 @return 是否删除成功
 */
+ (BOOL)zxg_deleteObjWithConditionStr:(NSString *)conditionStr;
/**
 * 删除全部数据，清空表
 */
+ (BOOL)zxg_deleteAll;

#pragma mark -- 更新
/**
 更新一条数据，更新条件是主键
 
 @return 是否更新成功
 */
- (BOOL)zxg_update;

/**
 使用事务批量更新数据，更新条件是主键
 
 @param array 要更新的模型数组
 
 @return 是否更新成功
 */
+ (BOOL)zxg_updateArray:(NSArray *)array;

#pragma mark -- 查询
/**
 * 查询全部数据
 */
+ (NSArray *)zxg_selectAll;

/**
 根据条件查询,查询的条件必须是主键id
 
 @param conditionStr 查询的条件语句 例如：@"where id = 5"
 
 @return 查询结果集合
 */
+ (NSArray *)zxg_selectObjWithConditionStr:(NSString *)conditionStr;


#pragma mark -- 子类重写
/**
 子类中重写，作用：忽略模型中不保存的属性
 
 @return 需要忽略的属性数组
 */
+ (NSArray *)zxg_ignoreProperties;

@end
