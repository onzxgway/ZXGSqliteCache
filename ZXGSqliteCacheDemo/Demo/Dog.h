//
//  ViewController.h
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import <Foundation/Foundation.h>

//一定要遵从NSCoding协议，实现其协议方法
@interface Dog : NSObject<NSCoding>

@property (copy,nonatomic)NSString *nickName;//狗的昵称

@end
