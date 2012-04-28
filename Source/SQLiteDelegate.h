//
//  SQLiteDelegate.h
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

#import "/usr/include/sqlite3.h"

#warning Add libsqlite3.dylib to your linking libraries!

@interface SQLiteDelegate : NSObject{
    NSString *databaseName;

    sqlite3 *database;

    NSString *errors;
}

- (sqlite3 *) database;
- (NSString *) errors;
- (NSString *) databaseName;

- (SQLiteDelegate *) initWithDatabase: (NSString *) initDatabaseName;
- (SQLiteDelegate *) initWithVersionedDatabase: (NSString *) initDatabaseName;
- (void) setDatabase: (NSString *)dbname;
- (NSString *) getDatabase;
- (BOOL) connectDatabase;
- (void) closeDatabase;
- (void) finalizeStatement:(sqlite3_stmt *)statement;

- (NSMutableDictionary *) selectSingle:(NSString *) sqlQuery;
- (NSMutableArray *) selectMultiple:(NSString *) sqlQuery;
- (BOOL) insert:(NSString *) table withTheFields:(NSDictionary *) fields;
- (BOOL) update:(NSString *) table set:(NSDictionary *) setFields where:(NSDictionary *) whereFields;
- (BOOL) deleteFrom:(NSString *) table where:(NSDictionary *) whereFields;
- (NSMutableArray *) query:(NSString *) sqlQuery;


@end
