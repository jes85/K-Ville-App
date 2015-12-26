 //
//  ScheduleSettingsViewController.m
//  Tent
//
//  Created by Jeremy on 10/17/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "ScheduleSettingsViewController.h"
#import "MySettingsTableViewCell.h"
#import "Constants.h"
#import <Parse/Parse.h>
#import "Person.h"
#import "AdminToolsViewController.h"

@interface ScheduleSettingsViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation ScheduleSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    if(self.isCreator){
        // display edit button in top right
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - UITableViewDataSource methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    /*
        if PFUser is admin
            then return an extra cell (admin tools). or have this be brought up by a diff bar button item
     */
    if(self.isCreator){
        return self.settings.count + 1;
    }

    return self.settings.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    NSDictionary *sectionDict = [self.settings objectForKey:[NSNumber numberWithInteger:section]];
    NSString *sectionHeader =[sectionDict objectForKey:@"sectionHeader"];
    if(self.isCreator && [sectionHeader isEqual:@"Admin"]) return 1; //Admin tools
    if([sectionHeader isEqual:@"Stats"]) return 1;
    NSArray *sectionData = [sectionDict objectForKey:@"sectionData"];
    return [sectionData count];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
     NSDictionary *sectionDict = [self.settings objectForKey:[NSNumber numberWithInteger:section]];
    return [sectionDict objectForKey:@"sectionHeader"];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *sectionDict = [self.settings objectForKey:[NSNumber numberWithInteger:indexPath.section]];
    NSString *sectionHeader =[sectionDict objectForKey:@"sectionHeader"];

    if(self.isCreator && [sectionHeader isEqualToString:@"Admin"]){
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"adminCell"];
        
        
        return cell;
    }else if([sectionHeader isEqualToString:@"Stats"]){
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"statsCell"];
        return cell;
    }else{
        MySettingsTableViewCell *cell = (MySettingsTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"SettingsCell" forIndexPath:indexPath];
        
        //change use json serializer
        
               NSArray *sectionData = [sectionDict objectForKey:@"sectionData"];
        NSDictionary *settingData = sectionData[indexPath.row];
        cell.settingNameLabel.text = [settingData objectForKey:@"title"];
        
        if([[settingData objectForKey:@"value"] isKindOfClass:[NSDate class]]){
             cell.settingValueLabel.text = [Constants formatDateAndTime:[settingData objectForKey:@"value"] withDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        }else{
             cell.settingValueLabel.text = [settingData objectForKey:@"value"];
        }
        
    
    
    return cell;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (IBAction)deleteScheduleButtonPressed:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Are you sure?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        if(self.isCreator){
            [self deleteEntireSchedule];
        }else{
            [self removeCurrentUserFromSchedule];
        }
        
    }];
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)removeCurrentUserFromSchedule
{
    PFObject *parseSchedule = [PFObject objectWithoutDataWithClassName:kGroupScheduleClassName objectId:self.schedule.parseObjectID]; //might need data
    PFObject *personToDelete;
    for(int i = 0; i<self.schedule.personsArray.count; i++){
        Person *person = self.schedule.personsArray[i];
        //TODO: maybe do it by index instead. Consider case where person is not associated with a user
        if([[[PFUser currentUser] objectId] isEqual: person.user.objectId]){
            [self.schedule.personsArray removeObjectAtIndex:i];
            personToDelete = [PFObject objectWithoutDataWithClassName:kPersonClassName objectId:person.parseObjectID];
            [parseSchedule removeObject:personToDelete forKey:kGroupSchedulePropertyPersonsInGroup];
            
            PFRelation *userGroupSchedule = [[PFUser currentUser] relationForKey:kUserPropertyGroupSchedules];
            [userGroupSchedule removeObject:parseSchedule];
            break;
        }
    }
    
    NSArray *objectsToSave = @[[PFUser currentUser], parseSchedule];
    [PFObject saveAllInBackground:objectsToSave block:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            [self performSegueWithIdentifier:@"scheduleDeleted" sender:self];
        }
    }];
    [personToDelete deleteInBackground];

    
    /*
    [[PFUser currentUser] saveInBackground];
    [parseSchedule saveInBackground];
    [personToDelete deleteInBackground];
     */
    
}

-(void)deleteEntireSchedule
{
    PFObject *parseSchedule = [PFObject objectWithoutDataWithClassName:kGroupScheduleClassName objectId:self.schedule.parseObjectID];
    
    NSMutableArray *personsArray = [[NSMutableArray alloc]initWithCapacity:self.schedule.personsArray.count];
    for(Person *person in self.schedule.personsArray){
        PFObject *parsePerson = [PFObject objectWithoutDataWithClassName:kPersonClassName objectId:person.parseObjectID];
        [personsArray addObject:parsePerson];
    }
    
    [parseSchedule deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(succeeded){
            [self performSegueWithIdentifier:@"scheduleDeleted" sender:self];
        }
    }];
    [PFObject deleteAllInBackground:personsArray];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if([segue.destinationViewController isKindOfClass:[AdminToolsViewController class]]){
        AdminToolsViewController *atvc = segue.destinationViewController;
        atvc.schedule = self.schedule;
    }
}


@end
