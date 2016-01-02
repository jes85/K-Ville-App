//
//  MyScheduleViewController.m
//  Tent
//
//  Created by Jeremy on 12/25/15.
//  Copyright (c) 2015 Jeremy. All rights reserved.
//

#import "MyScheduleViewController.h"
#import "EnterScheduleTableViewController.h"
#import "PickPersonTableViewController.h"
#import "Person.h"
#import "IntervalTableViewCell.h"
#import "Interval.h"
#import "Constants.h"
#import "PersonsInIntervalViewController.h"
#import "StatsViewController.h"
@interface MyScheduleViewController ()


@end

@implementation MyScheduleViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.allowsSelection = NO;
    self.navigationItem.leftBarButtonItem = nil;
    //[self decideIfEditingIsAllowed];
   
    if(self.canEdit){
        [self changeNavBarToShowEditButton];
    }else{
    }
    if([self.schedule.startDate timeIntervalSinceNow] < 0 && [self.schedule.endDate timeIntervalSinceNow] > 0){
        [super scrollToCurrentInterval];
        
    }
    
    //TODO: note: viewDidLoad is called in MeSchedule before prepareForSegue stuff in container vc. Maybe subclass twice and override viewDidAppear and viewDidLoad appropriately

}


-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    
    // overriding this method means we can attach custom functions to the button
    // this is the default action method for self.editButtonItem
    [super setEditing:editing animated:animated];
    
    // attaching custom actions here
    if (editing) {
        // we're in edit mode
        //[self.navigationItem setLeftBarButtonItem:self.cancelButton animated:animated];
        //self.tableView.allowsSelection = YES; //unnecessary because i set this in storyboard
        
    } else {
        // we're not in edit mode
        //[self.navigationItem setLeftBarButtonItem:nil animated:animated];
        //self.tableView.allowsSelection = NO;
        
        
    }
}
-(void)editButtonPressed
{
    if(self.schedule.assignmentsGenerated){
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Assignments Already Generated" message:@"Are you sure you want to edit?" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [self changeToEditMode];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
        [alert addAction:cancel];
        [alert addAction:yesAction];
        [self presentViewController:alert animated:YES completion:nil];
        
    }else{
        [self changeToEditMode];
    }
}
-(void)changeToEditMode
{
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    self.navigationItem.rightBarButtonItem = doneButton;
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];;
    [self.tableView setEditing:true animated:YES]; //true vs yes?
}
-(void)doneButtonPressed
{
    //do done button things
    [self saveEdits];
    [self changeNavBarToShowEditButton];
    [self.tableView setEditing:false animated:YES];
}
-(void)cancelButtonPressed
{
    //do cancel button things
    
    [self changeNavBarToShowEditButton];
    [self.tableView setEditing:false animated:YES];
}
-(void)changeNavBarToShowEditButton
{
    UIBarButtonItem *editButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(editButtonPressed)];
    self.navigationItem.rightBarButtonItem = editButton;
    
    self.navigationItem.leftBarButtonItem = nil;
}

-(BOOL)isMe{
    return [self.currentPerson.user.objectId isEqualToString:[[PFUser currentUser] objectId]];
}

/*
-(void)decideIfEditingIsAllowed
{
    self.isMe = [self.currentPerson.user.objectId isEqualToString:[[PFUser currentUser] objectId]];
    self.isCreator = [self.schedule.createdBy.objectId isEqualToString: [[PFUser currentUser] objectId]];
    self.canEdit =  (self.isMe && !self.schedule.assignmentsGenerated) | self.isCreator ;
}
*/


@end
