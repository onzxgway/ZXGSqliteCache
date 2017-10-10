//
//  ViewController.h
//  ZXGSqliteCache
//
//  Created by san_xu on 2017/4/5.
//  Copyright © 2017年 com.zxg.sqlitecache. All rights reserved.
//

#import "Dog.h"

@implementation Dog

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    
    if (self) {
         _nickName = [aDecoder decodeObjectForKey:@"nickName"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:_nickName forKey:@"nickName"];
}

@end
