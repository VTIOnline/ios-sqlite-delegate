//
//  ViewController.m
//  SQLite Test Suite
//
//  Created by Ben Vinson on 4/13/12.
//  Copyright (c) 2012 VTI. All rights reserved.
//

#import "ViewController.h"
#import "SQLiteDelegate.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize dblabel = _dblabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    SQLiteDelegate *DBConn = [[SQLiteDelegate alloc] initWithVersionedDatabase:@"DBTest.sqlite"];
    NSLog(@"%@",[DBConn selectSingle:@"SELECT * FROM _version"]);
//    [DBConn setDatabase:@"DBTest.sqlite"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    [dict setObject:@"ABC" forKey:@"test_name"];
    [dict setObject:@"1234" forKey:@"test_int"];
    NSMutableDictionary *dict2 = [[NSMutableDictionary alloc] init];
    [dict2 setObject:@"DEF" forKey:@"test_name"];
    NSMutableDictionary *dict3 = [[NSMutableDictionary alloc] init];
    [dict3 setObject:@"GHI" forKey:@"test_name"];
    
    [DBConn insert:@"test2" withTheFields:dict];
    [DBConn update:@"test2" set:dict2 where:dict];
    [DBConn deleteFrom:@"test2" where:dict3];
    
    self.dblabel.text = [DBConn getDatabase];
    NSLog(@"%@",[DBConn getDatabase]);
    NSMutableArray * results = [DBConn selectMultiple:@"SELECT * FROM test2"];
    NSLog(@"%@",results);
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
