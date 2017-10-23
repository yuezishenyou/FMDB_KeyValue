//
//  ViewController.m
//  Sqlite_KeyValue
//
//  Created by maoziyue on 2017/10/23.
//  Copyright © 2017年 maoziyue. All rights reserved.
//

#import "ViewController.h"
#import "HHKeyValue.h"

@interface ViewController ()
{
    NSInteger count;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"键值存储";
    
    count = 100;
    
    //[self base];//简单存取
    
    //[self base2];//持续存
    
    //[self base3]; //取全部
    
    //[self base4];//取一个
    
    //[self base5];//删除
    
    [self base6];//数据条数
    
    
}

- (void)base6
{
    HHKeyValue *manager = [HHKeyValue manager];
    
    NSInteger count = [manager getCountFromTable:@"MUSER"];
    
    NSLog(@"=---count:%ld---",count);

}



- (void)base5
{
    HHKeyValue *manager = [HHKeyValue manager];
    
    //[manager deleteObjectById:@"0" fromTable:@"MUSER"];
    
    [manager deleteObjectsByIdPrefix:@"3" fromTable:@"MUSER"];
    
}


- (void)base4
{
    HHKeyValue *manager = [HHKeyValue manager];
    
    KeyValueItem *item = [manager getYTKKeyValueItemById:@"10" fromTable:@"MUSER"];
    
    NSLog(@"---item:%@----",item);
    
}






- (void)base3
{
    HHKeyValue *manager = [HHKeyValue manager];
    
    NSArray *array = [manager  getAllItemsFromTable:@"MUSER"];

    for (KeyValueItem * item in array)
    {
        NSDictionary *dic = item.itemObject;
        
        NSLog(@"--dic:%@--",dic[@"girl"]);
    }
}



- (void)base2
{
    NSTimer *time = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(cunAction) userInfo:nil repeats:YES];
    [time fire];
}

- (void)cunAction
{
    HHKeyValue *manager = [HHKeyValue manager];
    
    NSString *key = [NSString stringWithFormat:@"%ld",count];
    
    NSDictionary *obj = @{@"id": key,
                          @"habby":@"不知道",
                          @"interseing":@"打球",
                          @"girl":@"dudu",
                          };
    [manager putObject:obj withId:key intoTable:@"MUSER"];
    
    count ++;
    
    
}


- (void)base
{
    HHKeyValue *manager = [HHKeyValue manager];

    NSString *key = @"1";
    NSDictionary *user = @{@"id": @1, @"name": @"tangqiao", @"age": @30};
    
    [manager putObject:user withId:key intoTable:@"MUSER"];
    
    id json = [manager getObjectById:@"1" fromTable:@"MUSER"];
    
    NSLog(@"---json:%@------",json);
    
}








@end
