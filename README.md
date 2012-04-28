ios-sqlite-delegate
===================

Object-based class for SQLite interaction with Xcode.

Note:
===================

This is far from perfect!  Use at your own risk.  If you make any changes that you would like to include with future versions, make a fork, commit the changes, and let me know. I will review the changes, and if they make a sufficient improvement, I will not only add the changes to the master fork, but also note your contribution.

License:
===================

Copyright (c) 2012 VTI. All rights reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

      http:www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Use:
====================
By default, you should only have to add the two files in the Source directory to your project, then add libsqlite3.dylib to your framework in Xcode.  Then:

- In the implementation file, import SQLiteDelegate.h
- Create a SQLiteDelegate object with either (in further examples, use DBConn):

    -[[SQLiteDelegate alloc] initWithVersionedDatabase:@"DBTest.sqlite"]

        This init will attempt to create a database unless there is one already there.
        If there is, it will look for a version table, which should have the version
        of the app.  If the table is missing, or the app version does not match,
        the database file will be deleted and copied back over from the app bundle.
        NOTE:  THE OLD DB WILL NOT BE BACKED UP.  ALL DATA WILL BE DESTROYED!
        
    -[[SQLiteDelegate alloc] initWithDatabase:@"DBTest.sqlite"]

        This init will attempt to create a database unless there is one already there.
        If there is, it will open the db for use.      
- From the SQLiteDelegate object, methods can be used to talk to the DB.
    -Insert using a dictionary where the keys and values are the columns and the values, respectively:

        (BOOL) [DBConn insert:@"test2" withTheFields:dict];
    -Update using the 'set' dictionary where the keys and values are the columns and the values, respectively, for the new values and the 'where' dictionary where the keys and values are the columns and the values, respectively:

        (BOOL) [DBConn update:@"test2" set:dict2 where:dict];
    -Delete from the table using a dictionary where the keys and values are the columns and the values, respectively, are used to delete specific records:

        (BOOL) [DBConn deleteFrom:@"test2" where:dict3];
    -Select multiple values (each element is a NSMutableDictionary of the columns (as the key) and the value):

        NSMutableArray * results = [DBConn selectMultiple:@"SELECT * FROM test2"];
    -Select single values (NSMutableDictionary of the columns (as the key) and the value):

        NSMutableDictionary *result = [DBConn selectSingle:@"SELECT * FROM test2 WHERE id=1"];
    -Query (NSMutableDictionary of the columns or result (as the key) and the value):
 
        NSMutableArray * results = [DBConn query:@"CREATE TABLE _version(version TEXT)"];
