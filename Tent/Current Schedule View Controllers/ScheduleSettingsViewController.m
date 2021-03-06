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
@property (weak, nonatomic) IBOutlet UIButton *deleteScheduleButton;

@end

@implementation ScheduleSettingsViewController

#pragma mark - View Controller Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    if(self.isCreator){
        [self.deleteScheduleButton setTitle:@"Delete Schedule" forState:UIControlStateNormal];
        
    }
    UIBarButtonItem *back = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.backBarButtonItem = back;


}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if(self.isCreator){
        return self.settings.count + 1; // extra admin tools cell
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
       
        NSArray *sectionData = [sectionDict objectForKey:@"sectionData"];
        NSDictionary *settingData = sectionData[indexPath.row];
        NSString *settingName = [settingData objectForKey:@"title"];
        NSString *settingValue;
        if([[settingData objectForKey:@"value"] isKindOfClass:[NSDate class]]){
            settingValue = [Constants formatDateAndTime:[settingData objectForKey:@"value"] withDateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle];
        }else{
            settingValue = [settingData objectForKey:@"value"];
        }
        
        if(self.isCreator && [[settingData objectForKey:@"isEditable"] boolValue] == YES){
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"editableSettingCell"];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textLabel.text = settingName;
            cell.detailTextLabel.text = settingValue;
            return cell;
        }
        else{
             MySettingsTableViewCell *cell = (MySettingsTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:@"uneditableSettingCell" forIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryNone;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.settingNameLabel.text = settingName;
            cell.settingValueLabel.text = settingValue;
            return cell;
        }
    
    }
}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if(cell.selectionStyle == UITableViewCellSelectionStyleNone){
        return nil;
    }
    return indexPath;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSMutableDictionary *sectionDict = [self.settings objectForKey:[NSNumber numberWithInteger:indexPath.section]];
    NSString *sectionHeader =[sectionDict objectForKey:@"sectionHeader"];
    if([sectionHeader isEqualToString:@"General"]){
        NSArray *sectionData = [sectionDict objectForKey:@"sectionData"];
        NSMutableDictionary *settingData = sectionData[indexPath.row];
        NSString *setting = [settingData objectForKey:@"title"];
        if([setting isEqualToString:@"Group Name"]){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Group Name" message:@"Enter a new group name." preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = self.schedule.groupName;
            }];
            UIAlertAction *changeAction = [UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                UITextField *textField = alert.textFields.firstObject;
                NSString *newGroupName = textField.text;
                //Update group name on parse
                PFQuery *query = [PFQuery queryWithClassName:kGroupScheduleClassName];
                [query getObjectInBackgroundWithId:self.schedule.parseObjectID block:^(PFObject *parseSchedule, NSError *error) {
                    if(!error){
                        parseSchedule[kGroupSchedulePropertyGroupName] = newGroupName;
                        [parseSchedule saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if(succeeded){
                                //Update UI
                                self.schedule.groupName = newGroupName;
                                settingData[@"value"] = newGroupName;
                                //Change this to only update desired cell
                                [tableView reloadData];
                                
                                //Notify other vcs of schedule change
                                NSDictionary *userInfo = @{kUserInfoLocalScheduleKey: self.schedule, kUserInfoLocalScheduleChangedPropertiesKey: @[kUserInfoLocalSchedulePropertyGroupName]};
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameScheduleChanged object:self userInfo:userInfo];
                            }
                        }];
                    }
                }];

            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancelAction];
            [alert addAction:changeAction];
            [self presentViewController:alert animated:YES completion:nil];
        }else if ([setting isEqualToString:@"Group Code"]){
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Change Group Code" message:@"Enter a new group code." preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = self.schedule.groupCode;
            }];
            UIAlertAction *changeAction = [UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                UITextField *textField = alert.textFields.firstObject;
                NSString *newGroupCode = textField.text;
                //Update group Code on parse
                PFQuery *query = [PFQuery queryWithClassName:kGroupScheduleClassName];
                [query getObjectInBackgroundWithId:self.schedule.parseObjectID block:^(PFObject *parseSchedule, NSError *error) {
                    if(!error){
                        parseSchedule[kGroupSchedulePropertyGroupCode] = newGroupCode;
                        [parseSchedule saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if(succeeded){
                                //Update UI
                                //consider updating UI before updating parse. it will look appear faster, and if it fails to save it's not a huge deal. Probably still safer to do this though
                                self.schedule.groupCode = newGroupCode;
                                settingData[@"value"] = newGroupCode;
                                //Change this to only update desired cell
                                [tableView reloadData];
                                
                                //Notify other vcs of schedule change
                                NSDictionary *userInfo = @{kUserInfoLocalScheduleKey: self.schedule, kUserInfoLocalScheduleChangedPropertiesKey: @[kUserInfoLocalSchedulePropertyOther]};
                                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameScheduleChanged object:self userInfo:userInfo];
                            }
                        }];
                    }
                }];
                
            }];
            UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
            [alert addAction:cancelAction];
            [alert addAction:changeAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
        //[self performSegueWithIdentifier:@"changeGroupNameOrCode" sender:cell];
    }else if([sectionHeader isEqualToString:@"Dates"]){
        //TODO: implement ability to change start and end dates
        //[self performSegueWithIdentifier:@"changeStartAndEndDateSegue" sender:cell];

        
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];


}

- (IBAction)deleteScheduleButtonPressed:(id)sender
{
    if(self.isCreator){
        [self showAlertForDeleteEntireSchedule];
    }else{
        if(self.schedule.assignmentsGenerated){
            [self showAlertToTellUserTheyAreNotAllowedToLeaveAfterAssignmentsGenerated];
        }else{
            [self showAlertForRemoveCurrentUser];

        }
    }
   
}

-(void)showAlertForDeleteEntireSchedule{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Delete Schedule" message:@"Are you sure you want to delete the entire schedule?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self deleteEntireSchedule];
        
    }];
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    [self presentViewController:alert animated:YES completion:nil];

}

-(void)showAlertToTellUserTheyAreNotAllowedToLeaveAfterAssignmentsGenerated
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sorry" message:@"You are not allowed to leave the schedule after assignments have been generated. Ask the group creator to remove you" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void)showAlertForRemoveCurrentUser
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Leave Schedule" message:@"Are you sure want to remove yourself from this schedule?" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        
    }];
    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self removeCurrentUserFromSchedule];
    }];
    [alert addAction:cancelAction];
    [alert addAction:deleteAction];
    [self presentViewController:alert animated:YES completion:nil];

    
}

-(void)dealloc{
    
}

-(void)removeCurrentUserFromSchedule
{
    PFObject *parseSchedule = [PFObject objectWithoutDataWithClassName:kGroupScheduleClassName objectId:self.schedule.parseObjectID]; //might need data
    PFObject *personToDelete;
    for(int i = 0; i<self.schedule.personsArray.count; i++){
        Person *person = self.schedule.personsArray[i];
        //TODO: maybe do it by index instead. Consider case where person is not associated with a user (but in that case this method would never be called?)
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
