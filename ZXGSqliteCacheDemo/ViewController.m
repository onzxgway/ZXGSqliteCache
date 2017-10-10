//
//  ViewController.m
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import "ViewController.h"
#import "ZXGFMDBModel.h"
#import "Person.h"
#import "Dog.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self demo];
}

- (void)demo {
        
        //1,实例化一个Person对象
        Person *p1 = [[Person alloc] init];
        p1.name = @"zxg";
        p1.age = 26;
        p1.height = 177.f;
        p1.hometown = @"anhui";
        
        p1.Hobbies = @[@"billards",@"basketball",@"football",@"drive"];
        Dog *d1 = [[Dog alloc] init];
        d1.nickName = @"litteStrong";
        p1.petDog = d1;
        p1.family = @{@"father":@"Jack",@"mother":@"Niya"};
        
        
        //
        Person *p2 = [[Person alloc] init];
        p2.name = @"kobe";
        p2.age = 40;
        p2.height = 197.f;
        p2.hometown = @"夏洛特";
        
        p2.Hobbies = @[@"football",@"basketball"];
        Dog *d2 = [[Dog alloc] init];
        d2.nickName = @"litteYellow";
        p2.petDog = d2;
        p2.family = @{@"wife":@"洛佩兹",@"son":@"no"};
        
        //
        Person *p3 = [[Person alloc] init];
        p3.name = @"James";
        p3.age = 28;
        p3.height = 203.f;
        p3.hometown = @"骑士";
        
        p3.Hobbies = @[@"USAfootball",@"basketball"];
        Dog *d3 = [[Dog alloc] init];
        d3.nickName = @"zangao";
        p3.petDog = d3;
        p3.family = @{@"wife":@"小悠悠",@"son":@"tow"};
        
        //    NSArray *arr = @[p1,p2,p3];
        
        //2,本地splite3数据库操作
    //*删除
        //    [Person zxg_deleteAll];//删除所有
        //    [Person zxg_deleteObjWithConditionStr:@"where age = 26"];//根据条件删除
    //*插入
        //    [p1 zxg_insertOne]; //单个对象插入   插入的时候，不用手动给id赋值，会自动根据插入的行数给id赋值。
        [Person zxg_insertArray:@[p1,p2,p3]]; //批量插入
    //*更新
        //    p3.id = 2; //更新一条数据
        //    [p3 zxg_update];
        
        //    p1.id = 1;//批量更新
        //    p2.id = 2;
        //    p3.id = 3;
        //    [Person zxg_updateArray:@[p1,p2,p3]];
        
        //    [p3 zxg_update];
        //    [Person zxg_updateArray:arr];
    //*查询
        //    NSArray *results = [Person zxg_selectAll]; //查询所有
        NSArray *results = [Person zxg_selectObjWithConditionStr:@"where id < 4"]; //条件查询
        for (Person *p in results) {
            NSLog(@"%@+++%@+++%f+++%@+++%zd",p.name,p.petDog.nickName,p.height,p.Hobbies,p.id);
        }
}

@end
