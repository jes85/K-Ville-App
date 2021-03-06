//
//  AdminToolsViewController.m
//  Tent
//
//  Created by Jeremy on 12/24/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "AdminToolsViewController.h"
#import "Constants.h"
#import "Person.h"
#import "AlgorithmSchedule.h"
#import <Parse/Parse.h>



@interface AdminToolsViewController ()

@end

@implementation AdminToolsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)generateAssignmentsButtonPressed:(id)sender {
    NSString *title = @"Generate Assignments";
    NSString *message = self.schedule.assignmentsGenerated ? @"Are you sure you want to generate new schedule assignments? The previous assignments will be lost" : @"Are you sure you want to generate assignments?";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self checkForErrorAndGenerateAssignments];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [alert addAction:proceedAction];
    [self presentViewController:alert animated:YES completion:nil];
}
- (IBAction)clearAssignmentsButtonPressed:(id)sender {
    NSString *title = @"Clear Assignments";
    if(self.schedule.assignmentsGenerated){
        NSString *message = @"Are you sure you want to clear the schedule assignments that were generated? The availabilities data will not change.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self clearAssignments];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancelAction];
        [alert addAction:proceedAction];
        [self presentViewController:alert animated:YES completion:nil];

    }else{
        NSString *message = @"You have not generated any assignments. Press the 'Generate Assignments' button to automatically generate them.";
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];

    }
}
- (IBAction)clearAvailabilitiesButtonPressed:(id)sender {
    NSString *title = @"Clear Availabilities";
    NSString *message = self.schedule.assignmentsGenerated ? @"Are you sure? Both the assignments and availabilties will be deleted." : @"Are you sure? Every group member's schedule will be reset.";
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *proceedAction = [UIAlertAction actionWithTitle:@"Proceed" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self clearAvailabilities];
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [alert addAction:proceedAction];
    [self presentViewController:alert animated:YES completion:nil];
        
}

-(void)checkForErrorAndGenerateAssignments
{
    //TODO: sort persons by createdAt first just in case
    AlgorithmSchedule *algorithmSchedule = [[AlgorithmSchedule alloc]initWithSchedule:self.schedule]; //might need a copy
    
    if([algorithmSchedule checkForError]){
        //deal with error
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error!" message:@"At least one time slot has less than the required number of people available. Would you like to generate assignments anyway?." preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            // User want to generate assignments anyway
            [algorithmSchedule makeAlgorithmWorkEvenThoughNotAllRequiredPersonsAreAvailable];
            [self generateAssignmentsAndUpdateParseUsingAlgorithmSchedule:algorithmSchedule];
        }]];

        [self presentViewController:alert animated:YES completion:nil];
        return;
    }else{
        [self generateAssignmentsAndUpdateParseUsingAlgorithmSchedule:algorithmSchedule];
    }
    
}

-(void)generateAssignmentsAndUpdateParseUsingAlgorithmSchedule:(AlgorithmSchedule *)algorithmSchedule
{
    NSMutableArray *assignments = [algorithmSchedule generateAssignments];
    if(assignments.count != self.schedule.personsArray.count) return; //error
    [self updateParseScheduleAfterGeneratingAssignmentsWithArrayOfNewPersonAssignmentsArrays:assignments];
    //NSMutableArray *newPersonsArray = [algorithmSchedule generateAssignments];
    //[self updateParseScheduleAfterGeneratingAssignmentsWithNewPersonsArray:newPersonsArray];

}

-(void)updateParseScheduleAfterGeneratingAssignmentsWithArrayOfNewPersonAssignmentsArrays:(NSMutableArray *)arrayOfNewPersonAssignmentsArrays
{
    //update Parse Schedule
    //update persons arrays and assignmentsGenerated
    //update local schedule
    //update persons arrays and assignmentsGenerated
    
    NSMutableArray *objectIds = [[NSMutableArray alloc]initWithCapacity:self.schedule.personsArray.count];
    for(Person *person in self.schedule.personsArray){
        [objectIds addObject:person.parseObjectID];
    }
    PFQuery *query = [PFQuery queryWithClassName:kPersonClassName];
    
    [query whereKey:@"objectId" containedIn:objectIds];
    [query orderByAscending:kParsePropertyCreatedAt];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            for(int i = 0; i<objects.count; i++){
                PFObject *parsePerson = objects[i];
                parsePerson[kPersonPropertyAssignmentsArray] = arrayOfNewPersonAssignmentsArrays[i];
                //TODO: make sure ith index is conisistent. might need to update Person indices on local after removing someone
            }
            [PFObject saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    PFQuery *scheduleQuery = [PFQuery queryWithClassName:kGroupScheduleClassName];
                    [scheduleQuery getObjectInBackgroundWithId:self.schedule.parseObjectID block:^(PFObject *object, NSError *error) {
                        object[kGroupSchedulePropertyAssignmentsGenerated] = [NSNumber numberWithBool:YES];
                        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            if(succeeded){
                                //update local schedule and notify other vcs
                                self.schedule.assignmentsGenerated = YES;
                                
                                [self updateLocalSchedulesAfterChangingPersonsArraysWithNewAssignmentsArrays:arrayOfNewPersonAssignmentsArrays];
                                
                                
                                //Alert success message
                                [self alertSuccessWithMessage:@"Assignments were successfully generated."];
                                
                                
                            }
                        }];
                    }];
                    
                }
            }];
        }
    }];
    
}

-(void)updateLocalSchedulesAfterChangingPersonsArraysWithNewAssignmentsArrays:(NSMutableArray *)newAssignmentsArrays
 {
     for(int i = 0; i<self.schedule.personsArray.count;i++){
         Person *person = self.schedule.personsArray[i];
         person.assignmentsArray = newAssignmentsArrays[i]; //assignments[[parsePerson[kPersonPropertyIndex] integerValue]];
         //TODO: make sure ith index is conisistent. might need to update Person indices on local after removing someone
     
     }
     
     [self.schedule createIntervalDataArrays]; //ineffient but works for now
     
     
     //Notify other vcs of schedule change
     NSDictionary *userInfo = @{kUserInfoLocalScheduleKey: self.schedule, kUserInfoLocalScheduleChangedPropertiesKey: @[kUserInfoLocalSchedulePropertyPersonsArray]};
     [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationNameScheduleChanged object:self userInfo:userInfo];
 
 
 }

-(void)clearAssignments
{
    //update parse
    NSMutableArray *parsePersonIds = [[NSMutableArray alloc]initWithCapacity:self.schedule.personsArray.count];
    NSMutableArray *clearedAssignmentsArrays = [[NSMutableArray alloc]initWithCapacity:self.schedule.personsArray.count];
    for(int i = 0; i<self.schedule.personsArray.count;i++){
        Person *person = self.schedule.personsArray[i];
        [parsePersonIds addObject:person.parseObjectID];
        [clearedAssignmentsArrays addObject:[self clearedAssignmentsArrayFromAssignmentsArray:person.assignmentsArray]];
        
    }
    //TODO: test completion handlers
    
    [AdminToolsViewController updateParsePersons:parsePersonIds WithNewAssignmentsArrays:clearedAssignmentsArrays completion:^{
        NSDictionary *dictionary = @{kGroupSchedulePropertyAssignmentsGenerated: [NSNumber numberWithBool:NO]};
        [AdminToolsViewController updateParseSchedule:self.schedule.parseObjectID WithDictionary: dictionary completion:^{
            
            //update local schedule and notify other vcs
            self.schedule.assignmentsGenerated = false;
            [self updateLocalSchedulesAfterChangingPersonsArraysWithNewAssignmentsArrays:clearedAssignmentsArrays];

            //Alert success message
            [self alertSuccessWithMessage:@"Successfully cleared assignments."];
            
        }];
    }];
   
   
    
}
-(NSMutableArray *)clearedAssignmentsArrayFromAssignmentsArray:(NSMutableArray *)assignmentsArray
{
    for(int i = 0; i<assignmentsArray.count;i++){
        if([assignmentsArray[i] isEqual:@2]) assignmentsArray[i] = @1;
    }
    return assignmentsArray;
}
-(void)clearAvailabilities
{
    //update parse
    NSMutableArray *parsePersonIds = [[NSMutableArray alloc]initWithCapacity:self.schedule.personsArray.count];
    NSMutableArray *clearedAssignmentsArrays = [[NSMutableArray alloc]initWithCapacity:self.schedule.personsArray.count];
    for(int i = 0; i<self.schedule.personsArray.count;i++){
        Person *person = self.schedule.personsArray[i];
        [parsePersonIds addObject:person.parseObjectID];
        [clearedAssignmentsArrays addObject:[self clearedAvailabilitiesArrayFromAssignmentsArray:person.assignmentsArray]];
        
    }
    
    [AdminToolsViewController updateParsePersons:parsePersonIds WithNewAssignmentsArrays:clearedAssignmentsArrays completion:^{
        if(self.schedule.assignmentsGenerated){
            NSDictionary *dictionary = @{kGroupSchedulePropertyAssignmentsGenerated: [NSNumber numberWithBool:NO]};
            [AdminToolsViewController updateParseSchedule:self.schedule.parseObjectID WithDictionary: dictionary completion:^{
                //update local schedule and notify other vcs
                self.schedule.assignmentsGenerated = false;
                [self updateLocalSchedulesAfterChangingPersonsArraysWithNewAssignmentsArrays:clearedAssignmentsArrays];
                
                //Alert success message
                [self alertSuccessWithMessage:@"Successfully cleared availabilities."];

            }];
        }else{
            //update local schedule and notify other vcs
            [self updateLocalSchedulesAfterChangingPersonsArraysWithNewAssignmentsArrays:clearedAssignmentsArrays];
            
            //Alert success message
            [self alertSuccessWithMessage:@"Successfully cleared availabilities"];
        }
    }];
    
}

-(NSMutableArray *)clearedAvailabilitiesArrayFromAssignmentsArray:(NSMutableArray *)assignmentsArray
{
    for(int i = 0; i<assignmentsArray.count;i++){
        assignmentsArray[i] = @0;
    }
    return assignmentsArray;
}

//Move to other class for use by others
+(void)updateParseSchedule:(NSString *)parseGroupScheduleId WithDictionary:(NSDictionary *)dictionary completion:(void(^)(void))callback
{
    //Make callback have an error parameter
    PFQuery *scheduleQuery = [PFQuery queryWithClassName:kGroupScheduleClassName];
    [scheduleQuery getObjectInBackgroundWithId:parseGroupScheduleId block:^(PFObject *object, NSError *error) {
        if(!error){
            for(NSString *schedulePropertyName in dictionary.allKeys){
                object[schedulePropertyName] = dictionary[schedulePropertyName];
            }
            [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    callback();
                    
                }
            }];
        }
    }];

    
}
+(void)updateParsePersons:(NSMutableArray *)parsePersonIds WithNewAssignmentsArrays:(NSMutableArray *)assignmentsArrays completion:(void(^)(void))callback
{
    PFQuery *query = [PFQuery queryWithClassName:kPersonClassName];
    //TODO: does it return objects in same order as parsePersonIds?
    // might need     [query orderByAscending:kParsePropertyCreatedAt];
    [query whereKey:@"objectId" containedIn:parsePersonIds];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if(!error){
            for(int i = 0; i<objects.count;i++){
                PFObject *parsePerson = objects[i];
                parsePerson[kPersonPropertyAssignmentsArray] = assignmentsArrays[i];
            }
            [PFObject saveAllInBackground:objects block:^(BOOL succeeded, NSError *error) {
                if(succeeded){
                    callback();

                }
            }];
        }
    }];
}
-(void)alertSuccessWithMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Success!" message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    [alert addAction:okAction];
    [self presentViewController:alert animated:YES completion:nil];
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
