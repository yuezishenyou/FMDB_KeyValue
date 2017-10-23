//
//  HHKeyValue.h
//  Sqlite_KeyValue
//
//  Created by maoziyue on 2017/10/23.
//  Copyright © 2017年 maoziyue. All rights reserved.
//

#import <Foundation/Foundation.h>







@interface KeyValueItem : NSObject

@property (strong, nonatomic) NSString *itemId;
@property (strong, nonatomic) id itemObject;
@property (strong, nonatomic) NSDate *createdTime;

@end





//********************** init *************************/

@interface HHKeyValue : NSObject

+ (instancetype)manager;

- (void)createDBWithName:(NSString *)dbName; //user.db

//- (void)createDBWithPath:(NSString *)dbPath;

- (void)createTableWithName:(NSString *)tableName;

- (BOOL)isTableExists:(NSString *)tableName;

- (void)clearTable:(NSString *)tableName;//删除表，表的结构存在

- (void)dropTable:(NSString *)tableName;//删除表，表的结构不存在

- (void)close;


//------------------------------ methods ------------------------------

- (void)putObject:(id)object withId:(NSString *)objectId intoTable:(NSString *)tableName;

- (id)getObjectById:(NSString *)objectId fromTable:(NSString *)tableName;

- (KeyValueItem *)getYTKKeyValueItemById:(NSString *)objectId fromTable:(NSString *)tableName;

- (void)putString:(NSString *)string withId:(NSString *)stringId intoTable:(NSString *)tableName;

- (NSString *)getStringById:(NSString *)stringId fromTable:(NSString *)tableName;

- (void)putNumber:(NSNumber *)number withId:(NSString *)numberId intoTable:(NSString *)tableName;

- (NSNumber *)getNumberById:(NSString *)numberId fromTable:(NSString *)tableName;

- (NSArray *)getAllItemsFromTable:(NSString *)tableName;

- (NSUInteger)getCountFromTable:(NSString *)tableName;

- (void)deleteObjectById:(NSString *)objectId fromTable:(NSString *)tableName;

- (void)deleteObjectsByIdArray:(NSArray *)objectIdArray fromTable:(NSString *)tableName;

- (void)deleteObjectsByIdPrefix:(NSString *)objectIdPrefix fromTable:(NSString *)tableName;//删除前缀
















@end
