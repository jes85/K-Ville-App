//
//  MySchedulesTableViewController.h
//  Tent
//
//  Created by Shrek on 8/10/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//
@class Schedule;
#import <UIKit/UIKit.h>

@interface MySchedulesTableViewController : UITableViewController

@property (nonatomic) NSMutableArray *schedules;
@property (nonatomic) Schedule *scheduleToAdd;

-(IBAction)addSchedule:(UIStoryboardSegue *)segue;
-(IBAction)cancelAddSchedule:(UIStoryboardSegue *)segue;
@end
