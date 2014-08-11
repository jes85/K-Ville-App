//
//  MySchedulesTableViewController.m
//  Tent
//
//  Created by Shrek on 8/10/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import "MySchedulesTableViewController.h"
#import "Schedule.h"
#import <Parse/Parse.h>
#import "HomeBaseTableViewController.h"

@implementation MySchedulesTableViewController

-(NSMutableArray *)schedules{
    if(!_schedules)_schedules = [[NSMutableArray alloc]init];
    return _schedules;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateSchedules];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)updateSchedules
{
    PFQuery *query = [PFQuery queryWithClassName:@"Schedule"];
    //query where some ID says its my schedule
    [query findObjectsInBackgroundWithBlock:^(NSArray *schedules, NSError *error) {
        if(!schedules){
            NSLog(@"Find failed");
        }else if ([schedules count]<1){
            NSLog(@"No My Schedules in Parse");
        }else{
            NSLog(@"Find My Schedules succeeded");
            for(PFObject *schedule in schedules){
                NSString *name = schedule[@"name"];
                NSMutableArray *availabilitiesSchedule = schedule[@"availabilitiesSchedule"];
                 NSMutableArray *assignmentsSchedule = schedule[@"assignmentsSchedule"];
                NSDate *startDate = schedule[@"startDate"];
                NSDate *endDate = schedule[@"endDate"];
                NSUInteger numHourIntervals = [schedule[@"numHourIntervals"] integerValue];
                
                Schedule *schedule = [[Schedule alloc]initWithName:name availabilitiesSchedule:availabilitiesSchedule assignmentsSchedule:assignmentsSchedule numHourIntervals:numHourIntervals startDate:startDate endDate:endDate] ;
                
                [self.schedules addObject:schedule];
            }
            
        }
        [self.tableView reloadData];
    }];


}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return [self.schedules count];
}


 - (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
 {
 UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"My Schedule Cell" forIndexPath:indexPath];
 
 // Configure the cell...
     Schedule *schedule = [self.schedules objectAtIndex:indexPath.row];
     cell.textLabel.text = schedule.name;
     
 
 return cell;
 }


/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
 } else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */


 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
 {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
     
     
     if([[segue destinationViewController] isKindOfClass:[HomeBaseTableViewController class]]){
         HomeBaseTableViewController *hbtvc = [segue destinationViewController];
         NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
         
         if(indexPath){

             hbtvc.schedule = self.schedules[indexPath.row];
         }
     }
 }

@end