# ZXGSqliteCache
存取速度快、使用简单方便的sqlite本地缓存框架

## Contents
* [Getting Started 【开始使用】](#Getting_Started)
	* [Features 【能做什么】](#Features)
	* [Installation 【安装】](#Installation)
* [Examples 【示例】](#Examples)
   * [最简单的单个模型对象存储](#SINGLE_Model_INSERT)
   * [模型对象数组批量存储](#AMOUNT_Model_INSERT)
   * [删除数据库中所有记录](#DELETE_ALL)
   * [根据条件删除数据库中的记录](#DELETE_JUDEG)
   * [更新一条记录](#UPDATE_ONE)
   * [批量更新](#UPDATE_AMOUNT)
   * [查询数据库中的所有记录](#SELECT_ALL)
   * [根据条件查询数据库中的记录](#SELECT_JUDGE)

# <a id="Getting_Started"></a> Getting Started【开始使用】
## <a id="Features"></a> Features【能做什么】
- ZXGSqliteCache是模型对象SQLite缓存的超轻量级框架
* 模型对象在本地sqlite数据库中的 `增` `删` `改` `查`
* 只需要一行代码，就能实现模型的数据库操作。

## <a id="Installation"></a> Installation【安装】
### Manually【手动导入】
- 【将`ZXGSqliteCache `文件夹中的所有源代码拽入项目中】
- 【导入主头文件：`#import "ZXGFMDBModel.h"`】

```objc
ZXGFMDBModel.h          ZXGFMDBModel.m
FMDBDatabaseTool.h      FMDBDatabaseTool.m
FMDB框架
```


# <a id="Examples"></a> Examples【示例】

### <a id="SINGLE_Model_INSERT"></a>【最简单的单个模型对象存储】
```objc
前提：1,Person类必须继承自ZXGFMDBModel
       @interface Person : ZXGFMDBModel
     2,//一定要遵从NSCoding协议，实现其协议方法
       @interface Dog : NSObject<NSCoding> ,因为Dog对象     要转换为二进制存储在数据库中。 

//1,实例化一个Person对象
        Person *p1 = [[Person alloc] init];
        p1.name = @"kobe";
        p1.age = 40;
        p1.height = 197.f;
        p1.hometown = @"anhui";
        
        p1.Hobbies = @[@"billards",@"basketball",@"football"];
        Dog *d1 = [[Dog alloc] init];
        d1.nickName = @"litteStrong";
        p1.petDog = d1;
        p1.family = @{@"father":@"Jack",@"mother":@"Niya"};
    
//2,单个对象插入        
        [p1 zxg_insertOne];  插入的时候，不用手动给id赋值，框架会自动根据插入的行数给id赋值。

```


### <a id="AMOUNT_Model_INSERT"></a>【模型对象数组批量存储】
```objc
前提：1,Person类必须继承自ZXGFMDBModel
       @interface Person : ZXGFMDBModel
     2,//一定要遵从NSCoding协议，实现其协议方法
       @interface Dog : NSObject<NSCoding> ,因为Dog对象     要转换为二进制存储在数据库中。 

//1,实例化一个Person对象
        Person *p1 = [[Person alloc] init];
        p1.name = @"kobe";
        p1.age = 40;
        p1.height = 197.f;
        p1.hometown = @"anhui";
        
        p1.Hobbies = @[@"billards",@"basketball",@"football"];
        Dog *d1 = [[Dog alloc] init];
        d1.nickName = @"litteStrong";
        p1.petDog = d1;
        p1.family = @{@"father":@"Jack",@"mother":@"Niya"};
        
        Person *p2 = [[Person alloc] init];
        p2.name = @"Jordan";
        p2.age = 55;
        p2.height = 197.f;
        p2.hometown = @"north";
        
        p2.Hobbies = @[@"golf",@"basketball"];
        Dog *d2 = [[Dog alloc] init];
        d2.nickName = @"litteYellow";
        p2.petDog = d2;
        p2.family = @{@"wife":@"nicola",@"son":@"no"};
    
//2,批量插入        
        [Person zxg_insertArray:@[p1,p2]];插入的时候，不用手动给id赋值，框架会自动根据插入的行数给id赋值。

```


### <a id="DELETE_ALL"></a>【删除数据库中所有记录】
```objc
前提：1,Person类必须继承自ZXGFMDBModel
       @interface Person : ZXGFMDBModel
     2,//一定要遵从NSCoding协议，实现其协议方法
       @interface Dog : NSObject<NSCoding> ,因为Dog对象     要转换为二进制存储在数据库中。 

     [Person zxg_deleteAll];//删除所有

```

### <a id="DELETE_JUDEG"></a>【根据条件删除数据库中的记录】
```objc
前提：1,Person类必须继承自ZXGFMDBModel
       @interface Person : ZXGFMDBModel
     2,条件语句就是类似于 where age = 26 这样符合SQL语法的语句。

     [Person zxg_deleteObjWithConditionStr:@"where age = 26"];//根据条件删除

```

### <a id="UPDATE_ONE"></a>【更新一条记录】
```objc

前提：1,更新的时候对象的id属性一定要赋值，因为更新的依据就是id

//1,实例化一个Person对象
        Person *p1 = [[Person alloc] init];
        p1.name = @"kobe";
        p1.age = 40;
        p1.height = 197.f;
        p1.hometown = @"anhui";
        p1.id = 1;//更新的时候一定要给id赋值。
        
        p1.Hobbies = @[@"billards",@"basketball",@"football"];
        Dog *d1 = [[Dog alloc] init];
        d1.nickName = @"litteStrong";
        p1.petDog = d1;
        p1.family = @{@"father":@"Jack",@"mother":@"Niya"};
    
//2,更新一条数据
        [p1 zxg_update];  

执行的结果就是把id=1的记录更新为p1。
```

### <a id="UPDATE_AMOUNT"></a>【批量更新】
```objc

前提：1,更新的时候对象的id属性一定要赋值，因为更新的依据就是id

//1,实例化一个Person对象
        Person *p1 = [[Person alloc] init];
        p1.name = @"kobe";
        p1.age = 40;
        p1.height = 197.f;
        p1.hometown = @"anhui";
        p1.id = 1;//更新的时候一定要给id赋值。
        
        p1.Hobbies = @[@"billards",@"basketball",@"football"];
        Dog *d1 = [[Dog alloc] init];
        d1.nickName = @"litteStrong";
        p1.petDog = d1;
        p1.family = @{@"father":@"Jack",@"mother":@"Niya"};
        
        Person *p3 = [[Person alloc] init];
        p3.name = @"James";
        p3.age = 28;
        p3.height = 203.f;
        p3.hometown = @"骑士";
        p3.id = 2;
        
        p3.Hobbies = @[@"USAfootball",@"basketball"];
        Dog *d3 = [[Dog alloc] init];
        d3.nickName = @"zangao";
        p3.petDog = d3;
        p3.family = @{@"wife":@"小悠悠",@"son":@"tow"};
    
//2,批量更新
        [Person zxg_updateArray:@[p1,p3]] 

执行的结果就是把id=1，2的记录更新为p1,p3。
```


### <a id="SELECT_ALL"></a>【查询数据库中的所有记录】
```objc
前提：1,查询结果数组中存放的是模型对象。

     NSArray *results = [Person zxg_selectAll]; //查询所有

```

### <a id="SELECT_JUDGE"></a>【根据条件查询数据库中的记录】
```objc
前提：1,查询结果数组中存放的是模型对象。
     2,条件语句必须符合sql语法。
     
    NSArray *results = [Person zxg_selectObjWithConditionStr:@"where id < 4"]; //条件查询

```


## 期待
* 如果在使用过程中遇到BUG，希望你能Issues我，谢谢（或者尝试下载最新的框架代码看看BUG修复没有）
* 如果你想为ZXGSqliteCache贡献代码，请拼命Pull Requests我