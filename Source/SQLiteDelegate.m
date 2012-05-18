//
//  SQLiteDelegate.m
//  
//
//  Created by Ben Vinson on 4/13/12.
//  Copyright (c) 2012 VTI. All rights reserved.
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.
//

#import "SQLiteDelegate.h"

@implementation SQLiteDelegate

- (sqlite3 *) database
{
    return database;
}

- (NSString *) errors
{
    return errors;
}

- (NSString *) databaseName
{
    return databaseName;
}

- (SQLiteDelegate *) initWithDatabase: (NSString *) initDatabaseName
{
    SQLiteDelegate *class = [[SQLiteDelegate alloc] init];
    [class setDatabase:initDatabaseName];
    return class;
}

- (SQLiteDelegate *) initWithVersionedDatabase: (NSString *) initDatabaseName
{
    SQLiteDelegate *class = [[SQLiteDelegate alloc] init];
    [class setDatabase:initDatabaseName];
    [class connectDatabase];
    NSDictionary *version = [class selectSingle:[NSString stringWithFormat:@"SELECT version FROM _version WHERE version='%@'", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]]];
    if([version count] == 0)
    {
        [class closeDatabase];
        NSError *error;
        BOOL goodPath = NO;
        BOOL isConnected = NO;
        NSString *docsDir;
        NSArray *dirPaths;
        
        // Get the documents directory
        dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        
        docsDir = [dirPaths objectAtIndex:0];
        
        NSFileManager *filemgr = [NSFileManager defaultManager];
        
        NSString *writableDBPath = [docsDir stringByAppendingPathComponent:[class databaseName]];
        NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:[[class databaseName] stringByReplacingOccurrencesOfString:@".sqlite" withString:@""] ofType:@"sqlite"];
        if ([filemgr fileExistsAtPath: writableDBPath ] == YES)
        {
            [filemgr removeItemAtPath:writableDBPath error:&error];
            goodPath = [filemgr copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
            if(!goodPath){
                NSLog(@"Failed to create writable database file with message '%@'.", [error localizedDescription]);
            }else {
                const char *dbpath = [writableDBPath UTF8String];
                
                if (sqlite3_open(dbpath, &database) == SQLITE_OK)
                {
                    isConnected = YES;
                    [class query:@"CREATE TABLE _version(version TEXT)"];
                    NSDictionary *versionInsert = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"%@",[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]] forKey:@"version"];
                    [class insert:@"_version" withTheFields:versionInsert];
                    [versionInsert autorelease];
                } else {
                    NSLog(@"Failed to open/create database:\n%@\n%s", databaseName, sqlite3_errmsg([class database]));
                    isConnected = NO;
                }
            }
            [defaultDBPath autorelease];
        }
        [docsDir autorelease];
        [dirPaths autorelease];
        [filemgr autorelease];
        [writableDBPath autorelease];
    }
    [version autorelease];
    return class;
}

- (void) setDatabase: (NSString *)dbname
{
    databaseName = [NSString stringWithFormat:@"%@", dbname];
}

- (NSString *) getDatabase
{
    return [NSString stringWithFormat:@"%@", databaseName];
}

- (BOOL) connectDatabase
{
    NSError *error;

    BOOL goodPath = NO;
    BOOL isConnected = NO;
    NSString *docsDir;
    NSArray *dirPaths;

    // Get the documents directory
    dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);

    docsDir = [dirPaths objectAtIndex:0];

    NSFileManager *filemgr = [NSFileManager defaultManager];

    NSString *writableDBPath = [docsDir stringByAppendingPathComponent:[self databaseName]];

    if ([filemgr fileExistsAtPath: writableDBPath ] == YES)
    {
		const char *dbpath = [writableDBPath UTF8String];

        if (sqlite3_open(dbpath, &database) == SQLITE_OK)
        {
            isConnected = YES;

        } else {
            NSLog(@"Failed to open/create database:\n\n%@\n\n%s", databaseName, sqlite3_errmsg([self database]));
            isConnected = NO;
        }
    }else{
        NSString *defaultDBPath = [[NSBundle mainBundle] pathForResource:[[self databaseName] stringByReplacingOccurrencesOfString:@".sqlite" withString:@""] ofType:@"sqlite"];
        goodPath = [filemgr copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
        if(!goodPath){
            NSLog(@"Failed to create writable database file with message '%@'.", [error localizedDescription]);
        }else {
            const char *dbpath = [writableDBPath UTF8String];
            
            if (sqlite3_open(dbpath, &database) == SQLITE_OK)
            {
                isConnected = YES;
                
            } else {
                NSLog(@"Failed to open/create database:\n%@\n%s", databaseName, sqlite3_errmsg([self database]));
                isConnected = NO;
            }
        }
        [defaultDBPath autorelease];
    }
    [docsDir autorelease];
    [dirPaths autorelease];
    [filemgr autorelease];
    [writableDBPath autorelease];
    return isConnected;
}

- (void) closeDatabase
{
    sqlite3_close(database);
}

- (void) finalizeStatement:(sqlite3_stmt *)statement
{
    sqlite3_finalize(statement);
}

- (NSMutableDictionary *) selectSingle:(NSString *) sqlQuery
{
    sqlite3_stmt    *statement;

    NSMutableDictionary *dataSet = [[NSMutableDictionary alloc] init];

    const char *query_stmt = [sqlQuery UTF8String];

    if([self connectDatabase]){

        if (sqlite3_prepare_v2([self database], query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if(sqlite3_step(statement) == SQLITE_ROW){
                int colCount = sqlite3_column_count(statement);
                for(int i = 0; i < colCount; i++){
                    [dataSet setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]];
                }
            }
        }else{
            NSLog(@"Query Preparation not OK!\n\n%@\n\n%s", sqlQuery, sqlite3_errmsg([self database]));
        }
        [self finalizeStatement:statement];
        [self closeDatabase];
    }else{
        NSLog(@"Connection to DB not opened!\n\n%s", sqlite3_errmsg([self database]));
    }
    statement = nil;
    return dataSet;
}

- (NSMutableArray *) selectMultiple:(NSString *) sqlQuery
{
    sqlite3_stmt    *statement;

    NSMutableArray *dataSet = [[NSMutableArray alloc] init];

    const char *query_stmt = [sqlQuery UTF8String];

    if([self connectDatabase]){

        if (sqlite3_prepare_v2([self database], query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            while(sqlite3_step(statement) == SQLITE_ROW){
                NSMutableDictionary *dataCols = [[NSMutableDictionary alloc] init];
                int colCount = sqlite3_column_count(statement);
                for(int i = 0; i < colCount; i++){
                    [dataCols setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]];
                }
                [dataSet addObject:dataCols];
                dataCols = nil;
            }
        }else{
            NSLog(@"Query Preparation not OK!\n\n%@\n\n%s", sqlQuery, sqlite3_errmsg([self database]));
        }
        [self finalizeStatement:statement];
        [self closeDatabase];
    }else{
        NSLog(@"Connection to DB not opened!");
    }
    statement = nil;
    return dataSet;
}


- (BOOL) insert:(NSString *) table withTheFields:(NSDictionary *) fields
{
    BOOL success = NO;
    sqlite3_stmt    *statement;
    NSArray *fieldNames = [fields allKeys];
    NSMutableArray *fieldValues = [[NSMutableArray alloc] initWithObjects:nil];
    for(NSString *field in fieldNames){
        [fieldValues addObject:[fields objectForKey:field]];
    }
    NSString *fieldNameSQL = [fieldNames componentsJoinedByString:@","];
    NSString *fieldValueSQL = [fieldValues componentsJoinedByString:@"','"];
    fieldValueSQL = [NSString stringWithFormat:@"'%@'", fieldValueSQL];
    NSString *insertSQL = [NSString stringWithFormat:@"INSERT INTO %@(%@) VALUES(%@)",table, fieldNameSQL, fieldValueSQL];
    const char *query_stmt = [insertSQL UTF8String];
    if([self connectDatabase]){
        if (sqlite3_prepare_v2([self database], query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                success = YES;
            }else{
                NSLog(@"Bad insert:\n\n%@\n\n%s", insertSQL, sqlite3_errmsg([self database]));
            }
        }else {
            NSLog(@"Bad preparation:\n\n%@\n\n%s", insertSQL, sqlite3_errmsg([self database]));
        }
    }else{
        NSLog(@"Connection to DB not opened!");
    }
    [self finalizeStatement:statement];
    [self closeDatabase];
    fieldNames = nil;
    [fieldNames autorelease];
    fieldValues = nil;
    [fieldValues autorelease];
    statement = nil;
    fields = nil;
    [fields autorelease];
    return success;
}

- (BOOL) update:(NSString *) table set:(NSDictionary *) setFields where:(NSDictionary *) whereFields
{
    BOOL success = NO;
    sqlite3_stmt    *statement;
    NSArray *setFieldNames = [setFields allKeys];
    NSArray *whereFieldNames = [whereFields allKeys];
    NSMutableArray *setFieldValues = [[NSMutableArray alloc] initWithObjects:nil];
    NSMutableArray *whereFieldValues = [[NSMutableArray alloc] initWithObjects:nil];
    for(NSString *field in setFieldNames){
        [setFieldValues addObject:[NSString stringWithFormat:@"%@='%@'",field,[setFields objectForKey:field]]];
    }
    NSString *setFieldSQL = [setFieldValues componentsJoinedByString:@","];
    NSString *whereFieldSQL = nil;
    NSString *updateSQL = [NSString stringWithFormat:@"UPDATE %@ SET %@",table, setFieldSQL];
    if(whereFieldNames.count > 0){
        for(NSString *field in whereFieldNames){
            [whereFieldValues addObject:[NSString stringWithFormat:@"%@='%@'",field,[whereFields objectForKey:field]]];
        }
        whereFieldSQL = [whereFieldValues componentsJoinedByString:@" AND "];
        updateSQL = [NSString stringWithFormat:@"%@ WHERE %@",updateSQL, whereFieldSQL];
    }
    else {
        NSLog(@"It's bad to not have a where in an update.  Definitely bad.  If you want to allow this, erase the lines that make the else block in the update function.");
        return NO;
    }
    const char *query_stmt = [updateSQL UTF8String];
    if([self connectDatabase]){
        if (sqlite3_prepare_v2([self database], query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                success = YES;
            }else{
                NSLog(@"Bad update:\n\n%@\n\n%s", updateSQL, sqlite3_errmsg([self database]));
            }
        }else {
            NSLog(@"Bad preparation:\n\n%@\n\n%s", updateSQL, sqlite3_errmsg([self database]));
        }
    }else{
        NSLog(@"Connection to DB not opened!");
    }
    [self finalizeStatement:statement];
    [self closeDatabase];
    setFieldNames = nil;
    [setFieldNames autorelease];
    whereFieldNames = nil;
    [whereFieldNames autorelease];
    setFieldValues = nil;
    [setFieldValues autorelease];
    whereFieldValues = nil;
    [whereFieldValues autorelease];
    setFieldSQL = nil;
    [setFieldSQL autorelease];
    statement = nil;
    updateSQL = nil;
    [updateSQL autorelease];
    return success;
}

- (BOOL) deleteFrom:(NSString *) table where:(NSDictionary *) whereFields
{
    BOOL success = NO;
    sqlite3_stmt    *statement;
    NSArray *whereFieldNames = [whereFields allKeys];
    NSMutableArray *whereFieldValues = [[NSMutableArray alloc] initWithObjects:nil];
    NSString *whereFieldSQL = nil;
    NSString *deleteSQL = [NSString stringWithFormat:@"DELETE FROM %@",table];
    if(whereFieldNames.count > 0){
        for(NSString *field in whereFieldNames){
            [whereFieldValues addObject:[NSString stringWithFormat:@"%@='%@'",field,[whereFields objectForKey:field]]];
        }
        whereFieldSQL = [whereFieldValues componentsJoinedByString:@" AND "];
        deleteSQL = [NSString stringWithFormat:@"%@ WHERE %@",deleteSQL, whereFieldSQL];
    }
    else {
        NSLog(@"It's bad to not have a where in a delete.  Definitely bad.  If you want to allow this, erase the lines that make up the else block in the deleteFrom function.");
        return NO;
    }
    const char *query_stmt = [deleteSQL UTF8String];
    if([self connectDatabase]){
        if (sqlite3_prepare_v2([self database], query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                success = YES;
            }else{
                NSLog(@"Bad delete.\n\n%@\n\n%s", deleteSQL, sqlite3_errmsg([self database]));
            }
        }else {
            NSLog(@"Bad preparation.\n\n%@\n\n%s", deleteSQL, sqlite3_errmsg([self database]));
        }
    }else{
        NSLog(@"Connection to DB not opened!");
    }
    [self finalizeStatement:statement];
    [self closeDatabase];
    whereFieldNames = nil;
    [whereFieldNames autorelease];
    whereFieldValues = nil;
    [whereFieldValues autorelease];
    statement = nil;
    deleteSQL = nil;
    [deleteSQL autorelease];
    return success;
}

- (NSMutableArray *) query:(NSString *) sqlQuery
{
    sqlite3_stmt    *statement;
    
    NSMutableArray *dataSet = [[NSMutableArray alloc] init];
    
    const char *query_stmt = [sqlQuery UTF8String];
    
    if([self connectDatabase]){
        
        if (sqlite3_prepare_v2([self database], query_stmt, -1, &statement, NULL) == SQLITE_OK)
        {
            if (sqlite3_step(statement) == SQLITE_DONE)
            {
                NSMutableDictionary *dataCols = [[NSMutableDictionary alloc] init];
                [dataCols setObject:@"Done" forKey:@"Result"];
                [dataSet addObject:dataCols];
                dataCols = nil;
                [dataCols autorelease];
            }else{
                sqlite3_reset(statement);
                while(sqlite3_step(statement) == SQLITE_ROW){
                    NSMutableDictionary *dataCols = [[NSMutableDictionary alloc] init];
                    int colCount = sqlite3_column_count(statement);
                    for(int i = 0; i < colCount; i++){
                        [dataCols setObject:[NSString stringWithUTF8String:(char *)sqlite3_column_text(statement, i)] forKey:[NSString stringWithUTF8String:sqlite3_column_name(statement, i)]];
                    }
                    [dataSet addObject:dataCols];
                    dataCols = nil;
                    [dataCols autorelease];
                }
            }
        }else{
            NSLog(@"Query Preparation not OK!\n\n%@\n\n%s", sqlQuery, sqlite3_errmsg([self database]));
        }
        [self finalizeStatement:statement];
        [self closeDatabase];
    }else{
        NSLog(@"Connection to DB not opened!");
    }
    statement = nil;
    return dataSet;
}

- (void)dealloc
{
    [databaseName release];
    [errors release];
    
    [super dealloc];
}

@end
