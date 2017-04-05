//
//  ViewController.h
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import "ZXGFMDBModel.h"
@class Dog;

@interface Person : ZXGFMDBModel  //***自定义模型了一定要继承自FMDBModel

@property (copy,nonatomic)NSString *name;//姓名
@property (assign,nonatomic)NSInteger age;//年龄
@property (assign,nonatomic)float height;//身高
@property (copy,nonatomic)NSString *hometown;//家乡

@property (strong,nonatomic)NSArray *Hobbies;//爱好
@property (strong,nonatomic)NSDictionary *family;//家人
@property (strong,nonatomic)Dog *petDog;//宠物狗 //Dog类一定要遵从NSCoding协议

@end
