//
//  PersonsInIntervalViewController.m
//  Tent
//
//  Created by Jeremy on 11/12/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "PersonsInIntervalViewController.h"
#import "Interval.h"
@interface PersonsInIntervalViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation PersonsInIntervalViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

-(void)findCurrentTimeInterval
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *datedifferenceComponents = [calendar components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:self.schedule.startDate toDate:[NSDate date] options:0];
    
    NSUInteger hours = datedifferenceComponents.hour;
    NSUInteger minutes = datedifferenceComponents.minute;
    
    //TODO: calculate total intervals based on interval length setting and hours/minutes
    
    Interval *interval = self.schedule.intervalArray[hours];
    self.availablePersonsArray = interval.availablePersons;
    self.assignedPersonsArray = interval.assignedPersons;
    

    
}
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if(self.displayCurrent==YES){
        [self findCurrentTimeInterval];
    }
    if(section==0){
        if([self.assignedPersonsArray count]<1) return 1;
        return [self.assignedPersonsArray count];
    }
    if(section==1){
        if([self.availablePersonsArray count]<1) return 1;
        return [self.availablePersonsArray count];
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    if(section == 0)
        return @"Assigned";
    if(section == 1)
        return @"Available";
    return @"";
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Person Cell" forIndexPath:indexPath];
    
    
    // Configure the cell...
    
    
    //Assigned Persons
    if(indexPath.section == 0){
        
        // Display NONE if no one is assigned
        if([self.assignedPersonsArray count]<1) {
            cell.textLabel.text = @"None";
            return cell;
        }
        
        
        // Display person's name
        NSString *personName = self.assignedPersonsArray[indexPath.row];
        cell.textLabel.text = personName;
    }
    
    
    // Available Persons
    if(indexPath.section == 1){
        
        // Display NONE if no one is available
        if([self.availablePersonsArray count]<1) {
            cell.textLabel.text = @"None";
            return cell;
        }
        
        // Display person's name
        NSString *personName = self.availablePersonsArray[indexPath.row];
        cell.textLabel.text = personName;
    }
    return cell;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end