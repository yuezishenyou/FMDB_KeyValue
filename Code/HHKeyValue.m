//
//  HHKeyValue.m
//  Sqlite_KeyValue
//
//  Created by maoziyue on 2017/10/23.
//  Copyright © 2017年 maoziyue. All rights reserved.
//

#import "HHKeyValue.h"
#import <FMDB.h>

#ifdef DEBUG
#define debugLog(...)    NSLog(__VA_ARGS__)
#define debugMethod()    NSLog(@"%s", __func__)
#define debugError()     NSLog(@"Error at %s Line:%d", __func__, __LINE__)
#else
#define debugLog(...)
#define debugMethod()
#define debugError()
#endif


#define PATH_OF_DOCUMENT    [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]

static NSString * const DEFAULT_DB_NAME = @"app.db";

static NSString *const CREATE_TABLE_SQL =
@"CREATE TABLE IF NOT EXISTS %@ ( \
id TEXT NOT NULL, \
json TEXT NOT NULL, \
createdTime TEXT NOT NULL, \
PRIMARY KEY(id)) \
";

static NSString *const UPDATE_ITEM_SQL = @"REPLACE INTO %@ (id, json, createdTime) values (?, ?, ?)";

static NSString *const QUERY_ITEM_SQL = @"SELECT json, createdTime from %@ where id = ? Limit 1";

static NSString *const SELECT_ALL_SQL = @"SELECT * from %@";

static NSString *const COUNT_ALL_SQL = @"SELECT count(*) as num from %@";

static NSString *const CLEAR_ALL_SQL = @"DELETE from %@";

static NSString *const DELETE_ITEM_SQL = @"DELETE from %@ where id = ?";

static NSString *const DELETE_ITEMS_SQL = @"DELETE from %@ where id in ( %@ )";

static NSString *const DELETE_ITEMS_WITH_PREFIX_SQL = @"DELETE from %@ where id like ? ";

static NSString *const DROP_TABLE_SQL = @" DROP TABLE '%@' ";



@implementation KeyValueItem

- (NSString *)description {
    return [NSString stringWithFormat:@"id=%@, value=%@, timeStamp=%@", _itemId, _itemObject, _createdTime];
}

@end



@interface HHKeyValue ()

@property (nonatomic, strong) FMDatabaseQueue *dbQueue;

@end



@implementation HHKeyValue

+ (instancetype)manager
{
    static HHKeyValue *_manager = nil;
    if (_manager == nil) {
        _manager = [[HHKeyValue alloc]init];
    }
    return _manager;
}

- (instancetype)init
{
    if (self = [super init]) {
        //[self createDBWithName:DEFAULT_DB_NAME];
    }
    return self;
}

+ (BOOL)checkTableName:(NSString *)tableName
{
    if (tableName == nil || tableName.length == 0 || [tableName rangeOfString:@" "].location != NSNotFound) {
        debugLog(@"-----ERROR,tbName: %@ format error.-----", tableName);
        return NO;
    }
    return YES;
}


- (void)createDBWithName:(NSString *)dbName
{
    NSString *path = [PATH_OF_DOCUMENT stringByAppendingPathComponent:dbName];
    NSLog(@"---path:%@----",path);
    
    if (_dbQueue) {
        [self close];
    }
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:path];
}


- (void)createDBWithPath:(NSString *)dbPath
{
    NSLog(@"---path:%@----",dbPath);
    if (_dbQueue) {
        [self close];
    }
    _dbQueue = [FMDatabaseQueue databaseQueueWithPath:dbPath];
}



- (void)createTableWithName:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return ;
    }
    NSString *sql = [NSString stringWithFormat:CREATE_TABLE_SQL ,tableName];
    
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:sql];
    }];
    if (result) {
        NSLog(@"--表格创建成功--");
    }
    else
    {
        NSLog(@"--表格创建失败--");
    }
}

- (BOOL)isTableExists:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName]){
        return NO;
    }
    
    __block BOOL result ;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db tableExists:tableName];
    }];
    if (!result) {
        NSLog(@"--error table exists--");
    }
    return result;
}

- (void)clearTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return ;
    }
    NSString *sql = [NSString stringWithFormat:CLEAR_ALL_SQL, tableName];
    __block BOOL res;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        res = [db executeUpdate:sql];
    }];
    if (!res) {
        NSLog(@"--error clear--");
    }
}

- (void)dropTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:DROP_TABLE_SQL,tableName];
    __block BOOL res;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        res = [db executeUpdate:sql];
    }];
    if (!res) {
        NSLog(@"--error drop--");
    }
}


- (void)putObject:(id)object withId:(NSString *)objectId intoTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) return ;

    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:&error];
    if (error) {
        return;
    }
    NSString *jsonString = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSDate *createTime = [NSDate date];
    NSString *sql = [NSString stringWithFormat:UPDATE_ITEM_SQL,tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase * _Nonnull db) {
        result = [db executeUpdate:sql, objectId, jsonString, createTime];
    }];
    if (result) {
        NSLog(@"---insert/replace success----");
    }
    if (result == NO) {
        NSLog(@"---insert/replace error----");
    }
}

- (id)getObjectById:(NSString *)objectId fromTable:(NSString *)tableName
{
    KeyValueItem * item = [self getYTKKeyValueItemById:objectId fromTable:tableName];
    if (item)
    {
        return item.itemObject;
    }
    else
    {
        return nil;
    }
}

- (KeyValueItem *)getYTKKeyValueItemById:(NSString *)objectId fromTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return nil;
    }
    NSString * sql = [NSString stringWithFormat:QUERY_ITEM_SQL, tableName];
    __block NSString * json = nil;
    __block NSDate * createdTime = nil;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql, objectId];
        if ([rs next]) {
            json = [rs stringForColumn:@"json"];
            createdTime = [rs dateForColumn:@"createdTime"];
        }
        [rs close];
    }];
    if (json) {
        NSError * error;
        id result = [NSJSONSerialization JSONObjectWithData:[json dataUsingEncoding:NSUTF8StringEncoding]
                                                    options:(NSJSONReadingAllowFragments) error:&error];
        if (error) {
            debugLog(@"ERROR, faild to prase to json");
            return nil;
        }
        KeyValueItem * item = [[KeyValueItem alloc] init];
        item.itemId = objectId;
        item.itemObject = result;
        item.createdTime = createdTime;
        return item;
    }
    else
    {
        return nil;
    }
}

- (void)putString:(NSString *)string withId:(NSString *)stringId intoTable:(NSString *)tableName
{
    if (string == nil) {
        debugLog(@"error, string is nil");
        return;
    }
    [self putObject:@[string] withId:stringId intoTable:tableName];
}

- (NSString *)getStringById:(NSString *)stringId fromTable:(NSString *)tableName
{
    NSArray * array = [self getObjectById:stringId fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}


- (void)putNumber:(NSNumber *)number withId:(NSString *)numberId intoTable:(NSString *)tableName {
    if (number == nil) {
        debugLog(@"error, number is nil");
        return;
    }
    [self putObject:@[number] withId:numberId intoTable:tableName];
}


- (NSNumber *)getNumberById:(NSString *)numberId fromTable:(NSString *)tableName
{
    NSArray * array = [self getObjectById:numberId fromTable:tableName];
    if (array && [array isKindOfClass:[NSArray class]]) {
        return array[0];
    }
    return nil;
}


- (NSArray *)getAllItemsFromTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return nil;
    }
    NSString * sql = [NSString stringWithFormat:SELECT_ALL_SQL, tableName];
    __block NSMutableArray * result = [NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        while ([rs next]) {
            KeyValueItem * item = [[KeyValueItem alloc] init];
            item.itemId = [rs stringForColumn:@"id"];
            item.itemObject = [rs stringForColumn:@"json"];
            item.createdTime = [rs dateForColumn:@"createdTime"];
            [result addObject:item];
        }
        [rs close];
    }];
    // parse json string to object
    NSError * error;
    for (KeyValueItem * item in result) {
        error = nil;
        id object = [NSJSONSerialization JSONObjectWithData:[item.itemObject dataUsingEncoding:NSUTF8StringEncoding] options:(NSJSONReadingAllowFragments) error:&error];
        if (error) {
            debugLog(@"ERROR, faild to prase to json.");
        } else {
            item.itemObject = object;
        }
    }
    return result;
}

- (NSUInteger)getCountFromTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return 0;
    }
    NSString * sql = [NSString stringWithFormat:COUNT_ALL_SQL, tableName];
    __block NSInteger num = 0;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet * rs = [db executeQuery:sql];
        if ([rs next]) {
            num = [rs unsignedLongLongIntForColumn:@"num"];
        }
        [rs close];
    }];
    return num;
}

- (void)deleteObjectById:(NSString *)objectId fromTable:(NSString *)tableName {
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return;
    }
    NSString * sql = [NSString stringWithFormat:DELETE_ITEM_SQL, tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, objectId];
    }];
    if (result)
    {
        NSLog(@"--删除成功--");
    }
    else
    {
        NSLog(@"--删除失败--");
    }
}

- (void)deleteObjectsByIdArray:(NSArray *)objectIdArray fromTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return;
    }
    NSMutableString *stringBuilder = [NSMutableString string];
    for (id objectId in objectIdArray) {
        NSString *item = [NSString stringWithFormat:@" '%@' ", objectId];
        if (stringBuilder.length == 0) {
            [stringBuilder appendString:item];
        } else {
            [stringBuilder appendString:@","];
            [stringBuilder appendString:item];
        }
    }
    NSString *sql = [NSString stringWithFormat:DELETE_ITEMS_SQL, tableName, stringBuilder];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    if (!result) {
        debugLog(@"ERROR, failed to delete items by ids from table: %@", tableName);
    }
}

- (void)deleteObjectsByIdPrefix:(NSString *)objectIdPrefix fromTable:(NSString *)tableName
{
    if ([HHKeyValue checkTableName:tableName] == NO) {
        return;
    }
    NSString *sql = [NSString stringWithFormat:DELETE_ITEMS_WITH_PREFIX_SQL, tableName];
    NSString *prefixArgument = [NSString stringWithFormat:@"%@%%", objectIdPrefix];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, prefixArgument];
    }];
    if (result) {
        NSLog(@"--删除成功--");
    }
    else
    {
        NSLog(@"--删除失败--");
    }
}






















- (void)close
{
    [_dbQueue close];
    _dbQueue = nil;
}




@end
