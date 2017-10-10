//
//  ZXGFMDBModel.m
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import "ZXGFMDBModel.h"
#import <objc/runtime.h>

static const NSString *NameKey = @"NameKey";
static const NSString *TypeKey = @"TypeKey";

@implementation ZXGFMDBModel

#pragma mark - 第一次初始化时，创建数据库和表
//如果在category中重写了initialize方法，那么如果当前类中引入了category头文件的话，则当前类的initialize的方法实现会被category定义的initialize方法替换掉。
//我在category中重写了原类的方法 而苹果的官方文档中明确表示  我们不应该在category中复写原类的方法，如果要重写 请使用继承
+ (void)initialize {
    if (self != [ZXGFMDBModel class]) {//避免该方法被多次调用
        [self zxg_createTable];
    }
}

#pragma mark - 创建数据库 -> 通过运行时拿到模型所有的属性和属性类型 -> 添加一个主键属性 -> 将所有的属性，主键拼接成（符合sqlite语法）字段定义语句 -> 执行语句，创建表以及表字段 -> 重新拿到所有的属性名，以及数据库中所有的字段名；将这2个数组进行对比，一旦发现某个属性在数据库没有对应的字段（漏掉了），数据库立即新增字段 -> 关闭数据库
// 创建表
+ (BOOL)zxg_createTable {
    //创建数据库，并且打开
    FMDatabase *database = [FMDatabase databaseWithPath:[FMDBDatabaseTool databasePath]];
    if (![database open]) {
#ifdef DEBUG
        NSLog(@"数据库打开失败!");
#endif
        return NO;
    }
    
    //
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:@"create table if not exists %@ (%@)",tableName,[self.class zxg_getcolumnAndTypeString]];
    if (![database executeUpdate:sql]) {
#ifdef DEBUG
        NSLog(@"创建表失败!");
#endif
        [database close];
        return NO;
    }
    
    //检测有无遗漏的字段，如果有，添加到表中
    NSArray *names = [self zxg_getAllProperties][NameKey];
    
    NSMutableArray *columns = [NSMutableArray array];
    //schema:纲要(既然是纲要，那么就不会涉及具体的数据，只会涉及字段名，字段类型...)。
    //需要传入的参数：表名，返回值：查询表后的结果集FMResultSet
    FMResultSet *resultSet = [database getTableSchema:tableName];
    while (resultSet.next) {
        //取出结果集中name对应的值，即字段的名称（取出所有的字段名）
        NSString *columnName = [resultSet stringForColumn:@"name"];
        [columns addObject:columnName];
    }
    
    //NSPredicate两个数组求交集，如果按照一般写法，需要2个遍历，但NSArray提供了一个filterUsingPredicate的方法，用了NSPredicate，就可以不用遍历！
    //谓词逻辑
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"not (self in %@)",columns];
    NSArray *results = [names filteredArrayUsingPredicate:predicate];
    
    for (NSString *column in results) {
        NSUInteger index = [names indexOfObject:column];
        NSString *type = [[self zxg_getAllProperties][TypeKey] objectAtIndex:index];
        //在表中添加新的字段（或者说新的列）
        NSString *sql = [NSString stringWithFormat:@"alter table %@ add column %@",tableName,[NSString stringWithFormat:@"%@ %@",column,type]];
        if (![database executeUpdate:sql]) {
#ifdef DEBUG
            NSLog(@"新增列失败!");
#endif
            [database close];
            return NO;
        }
    }
    
    [database close];
    return YES;
}

//判断表是否存在
+ (BOOL)zxg_isExistInTable
{
    __block BOOL result = NO;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db tableExists:NSStringFromClass(self.class)];
    }];
    return result;
}

//获取模型中的所有属性，并且添加一个主键字段id。这些数据都存入一个字典中
+ (NSDictionary *)zxg_getAllProperties {
    
    NSDictionary *dict = [self zxg_getPropertys];
    NSMutableArray *names = dict[NameKey];
    NSMutableArray *types = dict[TypeKey];
    
    [names insertObject:primaryId atIndex:0];
    [types insertObject:[NSString stringWithFormat:@"%@ primary key",SQLINTEGER] atIndex:0];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:names,NameKey,types,TypeKey, nil];
}

//使用runtime，获取当前类的所有属性以及属性对应的类型,并且存入字典中
+ (NSDictionary *)zxg_getPropertys {
    //0,
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *types = [NSMutableArray array];
    //1,
    unsigned int count = 0;  //count是属性的个数
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    //2,
    for (int i = 0; i < count; ++i) { //遍历属性数组properties
        objc_property_t property = properties[i];
        //1,获取属性名称
        NSString *propertyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        
        if ([[self zxg_ignoreProperties] containsObject:propertyName]) {
            continue; //子类模型中一些不需要创建数据库字段的property，直接跳过去
        }
        [names addObject:propertyName];
        
        //2,获取属性类型
        NSString *propertyType = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
        /*
         sqlite3 支持的数据类型：
         1.NULL：空值。
         2.INTEGER：带符号的整型，具体取决有存入数字的范围大小。
         3.REAL：浮点数字，存储为8-byte IEEE浮点数。
         4.TEXT：字符串文本。
         5.BLOB：二进制对象。
         
         c char         C unsigned char
         i int          I unsigned int
         l long         L unsigned long
         s short        S unsigned short
         d double       D unsigned double
         f float        F unsigned float
         q long long    Q unsigned long long
         B BOOL
         @ 对象类型 //指针 对象类型 如NSString 是@“NSString”
         
         64位下long 和long long 都是Tq
         */
        /*
         "T@\"NSString\",C,N,V_name",
         "T@\"NSString\",C,N,V_age",
         "T@\"NSArray\",&,N,V_infos",
         "T@\"User\",&,N,V_user"
         T@"NSDictionary",&,N,V_love
         
         Tq,N,V_height
         Td,N,V_weight
         */
        //把属性类型转换为对应的SQLite中的字段类型
        NSString *propType = nil;
        
        if ([propertyType hasPrefix:@"T@\"NSString\""]) { //字符串
            propType = SQLTEXT;
        } else if ([propertyType hasPrefix:@"T@\"NSArray\""]) { //数组
            propType = SQLBLOB;
        } else if ([propertyType hasPrefix:@"T@\"NSDictionary\""]) { //字典
            propType = SQLBLOB;
        } else if ([propertyType hasPrefix:@"T@"]) { //以T@开头的类型，除了集合，字符串等，就只剩下模型类型了
            propType = SQLMODEL;
        } else if ([propertyType hasPrefix:@"Ti"]||[propertyType hasPrefix:@"TI"]||[propertyType hasPrefix:@"Ts"]||[propertyType hasPrefix:@"TS"]||[propertyType hasPrefix:@"TB"]) { //i,I:整形， s,S:短整形， B:布尔
            propType = SQLINTEGER;
        } else { //double , float , long , long long
            propType = SQLREAL;
        }
        
        [types addObject:propType];
    }
    
    free(properties);
    return [NSDictionary dictionaryWithObjectsAndKeys:names,NameKey,types,TypeKey, nil];
}


#pragma mark - 创建对象时，给成员变量赋值
- (instancetype)init {
    self = [super init];
    if (self) {
        NSDictionary *dic = [self.class zxg_getAllProperties];
        _columnNames = [[NSMutableArray alloc] initWithArray:[dic objectForKey:NameKey]];
        _columnTypes = [[NSMutableArray alloc] initWithArray:[dic objectForKey:TypeKey]];
    }
    return self;
}

#pragma mark - API
/** 插入一条数据 */
- (BOOL)zxg_insertOne {
    
    NSString *tableName = NSStringFromClass(self.class);
    NSMutableString *keyString = [NSMutableString string];
    NSMutableString *valueString = [NSMutableString string];
    NSMutableArray *insertValues = [NSMutableArray array];
    //2,
    for (int i = 0; i < self.columnNames.count; ++i) {
        NSString *name = [self.columnNames objectAtIndex:i];
        NSString *type = [self.columnTypes objectAtIndex:i];
        //如果是主键，不处理
        if ([name isEqualToString:primaryId]) {
            continue;
        }
        [keyString appendFormat:@"%@,",name];
        [valueString appendString:@"?,"];
        
        //通过KVC将属性值取出来,转换为数据库存储类型
        id value = [self zxg_formatConvert:type name:name];
        //属性值可能为空
        if (!value) {
            value = @"";
        }
        [insertValues addObject:value];
    }
    //删除最后的那个","
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
    
    
    //
    __block BOOL result = NO;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@) values (%@)",tableName,keyString,valueString];
        //这个方法会自动到一个数组中去取值
        result = [db executeUpdate:sql withArgumentsInArray:insertValues];
        //获取数据库最后一个行的id
        self.id = result?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
#ifdef DEBUG
        NSLog(result?@"插入一条数据成功":@"插入一条数据失败");
#endif
    }];
    return result;
}

/** 使用事务批量插入 */
+ (BOOL)zxg_insertArray:(NSArray *)array {
    
    //1,遍历模型数组,判断模型类是否继承自FMDBModel。
    if (![self zxg_isSubclassOfFMDBModel:array])return NO;
    
    //FMDB支持事务，存入一条数据的具体过程是：开始新事物->插入数据->提交事务
    //使用事务处理就是将所有任务执行完成以后将结果一次性提交到数据库，如果此过程出现异常则会执行回滚操作，这样节省了大量的重复提交环节所浪费的时间
    //2,事务批量操作
    __block BOOL result = YES;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSString *tableName = NSStringFromClass(self.class);
        NSMutableString *keyString = [NSMutableString string];
        NSMutableString *valueString = [NSMutableString string];
        NSMutableArray *insertValues = [NSMutableArray array];
        
        for (ZXGFMDBModel *model in array) {
            //1,
            [insertValues removeAllObjects];
            [keyString deleteCharactersInRange:NSMakeRange(0, keyString.length)];
            [valueString deleteCharactersInRange:NSMakeRange(0, valueString.length)];
            //2,
            for (int i = 0; i < model.columnNames.count; ++i) {
                NSString *name = [model.columnNames objectAtIndex:i];
                NSString *type = [model.columnTypes objectAtIndex:i];
                //如果是主键，不处理
                if ([name isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@,",name];
                [valueString appendString:@"?,"];
                
                //通过KVC将属性值取出来,转换为数据库存储类型
                id value = [model zxg_formatConvert:type name:name];
                
                //属性值可能为空
                if (!value) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            //删除最后的那个","
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [valueString deleteCharactersInRange:NSMakeRange(valueString.length - 1, 1)];
            
            NSString *sql = [NSString stringWithFormat:@"insert into %@ (%@) values (%@)",tableName,keyString,valueString];
            //这个方法会自动到一个数组中去取值
            result = [db executeUpdate:sql withArgumentsInArray:insertValues];
            //获取数据库最后一个行的id
            model.id = result?[NSNumber numberWithLongLong:db.lastInsertRowId].intValue:0;
            if (result) {
#ifdef DEBUG
                NSLog(@"批量插入成功");
#endif
            } else {
#ifdef DEBUG
                NSLog(@"批量插入失败");
#endif
                *rollback = YES;//如果失败了，一定要回滚（一条插入失败，所有的都失败）
                result = NO;
                return;
            }
        }
    }];
    
    return result;
}


/** 根据条件删除 */
+ (BOOL)zxg_deleteObjWithConditionStr:(NSString *)conditionStr {
    
    NSString *sql = [NSString stringWithFormat:@"delete from %@ %@",NSStringFromClass([self class]),conditionStr];
    __block BOOL result = YES;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
        if (!result) {
#ifdef DEBUG
            NSLog(@"删除失败！");
#endif
        }
    }];
    return result;
}

/** 删除全部数据 */
+ (BOOL)zxg_deleteAll {
    
    __block BOOL result = NO;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inDatabase:^(FMDatabase *db) {
        NSString *sql = [NSString stringWithFormat:@"delete from %@",NSStringFromClass(self.class)];
        result = [db executeUpdate:sql];
#ifdef DEBUG
        NSLog(result?@"清空成功":@"清空失败");
#endif
    }];
    return result;
}

/** 更新一条数据，更新条件是主键 */
- (BOOL)zxg_update {
    
    id primaryKey = [self valueForKey:primaryId];
    if (!primaryKey || primaryKey <= 0) {
        return NO;
    }
    
    NSMutableString *keyString = [NSMutableString string];
    NSMutableArray *values = [NSMutableArray  array];
    for (int i = 0; i < self.columnNames.count; ++i) {
        NSString *name = [self.columnNames objectAtIndex:i];
        if ([name isEqualToString:primaryId]) {
            continue;
        }
        [keyString appendFormat:@"%@ = ?,",name];
        id value = [self zxg_formatConvert:[self.columnTypes objectAtIndex:i] name:name];
        if (!value) {
            value = @"";
        }
        [values addObject:value];
    }
    [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
    [values addObject:primaryKey];
    
    NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@ = ?;",NSStringFromClass([self class]),keyString,primaryId];
    __block BOOL result = YES;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withArgumentsInArray:values];
    }];
#ifdef DEBUG
    NSLog(result?@"插入成功":@"插入失败");
#endif
    return result;
}

/** 使用事务批量更新 */
+ (BOOL)zxg_updateArray:(NSArray *)array {
    
    //1,遍历模型数组,判断模型类是否继承自FMDBModel。
    if (![self zxg_isSubclassOfFMDBModel:array])return NO;
    
    //2,事务批量操作
    __block BOOL result = YES;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSMutableString *keyString = [NSMutableString string];
        NSMutableArray *insertValues = [NSMutableArray array];
        
        for (ZXGFMDBModel *model in array) {
            //0,
            [keyString deleteCharactersInRange:NSMakeRange(0, keyString.length)];
            [insertValues removeAllObjects];
            //1,
            id primaryKey = [model valueForKey:primaryId];
            if (!primaryKey || primaryKey <= 0) {
                result = NO;
                *rollback = YES;
#ifdef DEBUG
                NSLog(@"批量更新失败");
#endif
                return;
            }
            
            //2,
            for (int i = 0; i < model.columnNames.count; ++i) {
                NSString *name = [model.columnNames objectAtIndex:i];
                NSString *type = [model.columnTypes objectAtIndex:i];
                //如果是主键，不处理
                if ([name isEqualToString:primaryId]) {
                    continue;
                }
                [keyString appendFormat:@"%@ = ?,",name];
                
                //通过KVC将属性值取出来,转换为数据库存储类型
                id value = [model zxg_formatConvert:type name:name];
                
                //属性值可能为空
                if (!value) {
                    value = @"";
                }
                [insertValues addObject:value];
            }
            //删除最后的那个","
            [keyString deleteCharactersInRange:NSMakeRange(keyString.length - 1, 1)];
            [insertValues addObject:primaryKey];
            
            NSString *sql = [NSString stringWithFormat:@"update %@ set %@ where %@ = ?",NSStringFromClass(model.class),keyString,primaryId];
            //这个方法会自动到一个数组中去取值
            result = [db executeUpdate:sql withArgumentsInArray:insertValues];
            if (result) {
#ifdef DEBUG
                NSLog(@"批量更新成功");
#endif
            } else {
#ifdef DEBUG
                NSLog(@"批量更新失败");
#endif
                *rollback = YES;//如果失败了，一定要回滚（一条插入失败，所有的都失败）
                result = NO;
                return;
            }
        }
    }];
    
    return result;
    
}


/** 查询全部数据 */
+ (NSArray *)zxg_selectAll {
    return [self zxg_selectObjWithConditionStr:@""];
}

/** 根据条件查询数据 */
//查询结果先赋值给模型，再用一个数组装起来
+ (NSArray *)zxg_selectObjWithConditionStr:(NSString *)conditionStr {
    
    __block NSArray *results = nil;
    [[FMDBDatabaseTool shareFMDBGetDatabaseTool].dbQueue inDatabase:^(FMDatabase *db) {
        //拿到表名,查询条件就是参数conditionStr
        NSString *sql = [NSString stringWithFormat:@"select * from %@ %@",NSStringFromClass(self.class),conditionStr];
        FMResultSet *resultSet = [db executeQuery:sql];
        results = [self zxg_formatConvert:resultSet];
    }];
    
    return results;
    
}

#pragma mark - 留给子类重写
+ (NSArray *)zxg_ignoreProperties {
    return @[];
}


#pragma mark - 私有方法
//遍历模型数组,判断模型类是否继承自FMDBModel
+ (BOOL)zxg_isSubclassOfFMDBModel:(NSArray *)array {
    /*
     oc中遍历集合有三种方法：1，for循环 2，forin循环 3，block遍历(缺点是无序)， 效率依次提升。
     */
    __block BOOL isSubClass = YES;
    [array enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isKindOfClass:[ZXGFMDBModel class]]) {
            isSubClass = NO;
            *stop = YES;//停止遍历
        }
    }];
    return isSubClass;
    
}

//把属性值转换为数据库存储所需类型
- (id)zxg_formatConvert:(NSString *)type name:(NSString *)name{
    id value = nil;
    if ([type isEqualToString:SQLBLOB]) { //集合存储前先反序列化为二进制数据
        id list = [self valueForKey:name];
        value = [NSKeyedArchiver archivedDataWithRootObject:list];
    } else if([type isEqualToString:SQLMODEL]){//模型存储前先反序列化为二进制数据
        id mo = [self valueForKey:name];
        value = [NSKeyedArchiver archivedDataWithRootObject:mo];
    } else {
        value = [self valueForKey:name];
    }
    return value;
}

//把查询结果转为模型数组
+ (NSArray *)zxg_formatConvert:(FMResultSet *)resultSet{
    
    NSMutableArray *users = [NSMutableArray array];
    
    while ([resultSet next]) {
        ZXGFMDBModel *model = [[[self class] alloc] init];
        for (int i = 0; i < model.columnNames.count; ++i) {
            NSString *columnName = [model.columnNames objectAtIndex:i];
            NSString *columnType = [model.columnTypes objectAtIndex:i];
            
            id value = nil;
            if ([columnType isEqualToString:SQLBLOB]) {
                NSData *data = [resultSet dataForColumn:columnName];
                value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }else if ([columnType isEqualToString:SQLMODEL]){
                NSData *data = [resultSet dataForColumn:columnName];
                value = [NSKeyedUnarchiver unarchiveObjectWithData:data];
            }else if ([columnType isEqualToString:SQLTEXT]) {
                value = [resultSet stringForColumn:columnName];
            } else {
                value = [NSNumber numberWithLongLong:[resultSet longLongIntForColumn:columnName]];
            }
            
            [model setValue:value forKey:columnName];
        }
        
        [users addObject:model];
        FMDBRelease(model);
    }
    return users;
}

//将属性名与属性类型拼接成sqlite语句：name text,height Real,...
+ (NSString *)zxg_getcolumnAndTypeString {
    
    NSDictionary *dict = [self zxg_getAllProperties];
    
    NSArray *names = dict[NameKey];//字段名称
    NSArray *types = dict[TypeKey];//字段类型
    
    NSMutableString *mutStr = [NSMutableString string];
    for (int i = 0; i < names.count; ++i) {
        NSString *comStr = [NSString stringWithFormat:@"%@ %@,",names[i],types[i]];
        [mutStr appendString:comStr];
    }
    
    [mutStr deleteCharactersInRange:NSMakeRange(mutStr.length - 1, 1)];//去掉最后一个多余的逗号
    return mutStr;
}

@end

