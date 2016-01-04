//
//  MySchedulesTableViewController.m
//  Tent
//
//  Created by Jeremy on 8/10/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import "MySchedulesTableViewController.h"
#import "MySchedulesTableViewCell.h"

#import "Constants.h"
#import "Schedule.h"
#import "HomeGame.h"
#import "Person.h"



#import "MyPFLogInViewController.h"
#import "MyPFSignUpViewController.h"

#import "MyScheduleContainerViewController.h"
#import "NewScheduleTableViewController.h"

@interface MySchedulesTableViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addScheduleButton;
@property PFUser *user;
@property (nonatomic) UIActivityIndicatorView *loadingWheel;


@property (nonatomic) NSUInteger scrollRow;



@end


@implementation MySchedulesTableViewController

#pragma mark - View Controller Lifecycle

//TODO: Review the process of retreiving my schedules.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    PFUser *currentUser = [PFUser currentUser];
    if(currentUser){
        //self.user = currentUser;
        self.loadingWheel.center = self.tableView.center;
        [self.loadingWheel startAnimating];
        [self getMySchedules];
        UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
        refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Reload Data"];
        [refresh addTarget:self action:@selector(refreshSchedules) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refresh;
        
        UIBarButtonItem *back = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
        self.navigationItem.backBarButtonItem = back;
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scheduleChanged:) name:kNotificationNameScheduleChanged object:nil];
    }
    else{ //No user logged in
        [self displayLoginAndSignUpViews];
    }
    
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    PFUser *currentUser = [PFUser currentUser];
    if(!currentUser){
        /*
        [self resetUserScheduleData];
        [self.tableView setNeedsDisplay];
        [self displayLoginAndSignUpViews];
         */
    }else if(currentUser!=self.user){
        /*
        self.user = currentUser;
        //maybe move to didLogIn
        [self.loadingWheel startAnimating];
        [self resetUserScheduleData];
        [self.tableView reloadData];
        [self getMySchedules];
         */
        
    }else{
        //currentUser
        /*
        if(self.updatedScheduleIndexPath){
            [self updateTableViewRowAtIndexPath:self.updatedScheduleIndexPath];
            self.updatedScheduleIndexPath = nil;
        }
         */
    }
}

-(void)scrollToCurrentInterval
{
    CGPoint point = self.tableView.contentOffset;
    point.y = [self calculateContentOffset];
    self.tableView.contentOffset = point;
}
-(NSUInteger)scrollRow
{
    NSUInteger scrollRow = 0;
    Schedule *lastSchedule = self.schedules.lastObject;
    HomeGame *lastHomeGame = lastSchedule.homeGame;
    if([lastHomeGame.gameTime timeIntervalSinceNow] < 0) return 0; //if all games have occurred, just show all of them
    for(int i=0;i<self.schedules.count - 1;i++){ //don't need to check the last game twice
        Schedule *schedule = self.schedules[i];
        HomeGame *game = schedule.homeGame;
        if([game.gameTime timeIntervalSinceNow] < 0){
            scrollRow = i+1;
        }
    }
    return scrollRow;
}
-(NSUInteger)calculateContentOffset
{
    CGRect rect = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:self.scrollRow inSection:0]];
    return rect.origin.y;
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[super dealloc];
}
-(void)scheduleChanged:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    Schedule *schedule = userInfo[kUserInfoLocalScheduleKey];
    NSArray *changedProperties = userInfo[kUserInfoLocalScheduleChangedPropertiesKey];
    BOOL UIUpdateNeeded =[changedProperties containsObject:kUserInfoLocalSchedulePropertyGroupName];
    
    [self updateLocalSchedule:schedule updateUI:UIUpdateNeeded];

}

-(void)updateLocalSchedule: (Schedule *)updatedSchedule updateUI:(BOOL)UIUpdateNeeded
{
    for(int i = 0; i <self.schedules.count; i++){
        Schedule *localSchedule = (Schedule *)self.schedules[i];
        if([localSchedule.parseObjectID isEqualToString:updatedSchedule.parseObjectID]){
            //update data
            self.schedules[i] = updatedSchedule;
            if(UIUpdateNeeded){
                //update UI
                [self updateTableViewRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];

            }
            return;
            //test
            //this works (don't need to save a bool and then wait for viewDidAppear to change view. can do it when notification is received.
            //is there a performance improvement if i wait until viewDidAppear?
            //when do vcs get deallocated? if its deallocated, will it ever receive the notification?
            //i bet since its part of navigation vc, it's not deallocated. but if its a modal (i.e. settings view), when its closed it is deallocated UPDATE: this is true. i tested it
            //but if its deallocated, then viewDidLoad will be called, and as long as the vc that calls it has had its schedule updated, the new vc will be updated in prepareForSegue and will update its UI in viewDidLoad
            /*
            updatedSchedule.groupName = @"Test";
            self.schedules[i] = updatedSchedule;
            [self updateTableViewRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
             */
            //self.updatedScheduleIndexPath = [NSIndexPath indexPathForRow:i inSection:0];
        }
    }
}
-(void)updateTableViewRowAtIndexPath:(NSIndexPath *)indexPath
{
    //do i need to dispatch get main queue first?
    [self.tableView beginUpdates];
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

-(void)refreshSchedules
{
    [self getMySchedules];
    [self performSelector:@selector(stopRefresh) withObject:nil afterDelay:0];

}
-(void)stopRefresh
{
    [self.refreshControl endRefreshing];
}
-(void)resetUserScheduleData
{
    self.schedules = nil;
}


-(UIActivityIndicatorView *)loadingWheel
{
    if(!_loadingWheel){
        _loadingWheel = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        _loadingWheel.transform = CGAffineTransformMakeScale(1.75, 1.75);
    }
    return _loadingWheel;
}

#pragma mark - Login/Signup Control

-(void)displayLoginAndSignUpViews
{
    // Create the log in view controller
    MyPFLogInViewController *logInViewController = [[MyPFLogInViewController alloc]init];
    logInViewController.fields = PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten;
    
    [logInViewController setDelegate:self]; //set this class as the logInViewController's delegate
    
    // Create the sign up view controller
    MyPFSignUpViewController *signUpViewController = [[MyPFSignUpViewController alloc]init];
    signUpViewController.fields = PFSignUpFieldsDefault | PFSignUpFieldsAdditional;//can you do more than 1 additional?
    [signUpViewController setDelegate:self]; //set this class as the signUpViewController's delegate
    
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];
    
    //present the log in view controller
    [self presentViewController:logInViewController animated:YES completion:nil];
    
}
#pragma mark - Log In View Controller Delegate
// Sent to the delegate to determine whether the log in request should be submitted to the server.
- (BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password {
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                message:@"Make sure you fill out all of the information!"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}


// Sent to the delegate when a PFUser is logged in.
// (customize this later)
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user
{
    [self.loadingWheel startAnimating];
    [self resetUserScheduleData];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:NULL];
    [self getMySchedules];

}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error {
    NSLog(@"Failed to log in...");
    [[[UIAlertView alloc] initWithTitle:@"Login unsuccessful"
                                message:@"Please re-enter your information"
                               delegate:nil
                      cancelButtonTitle:@"ok"
                      otherButtonTitles:nil] show];
    //maybe clear password
}

// Sent to the delegate when the log in screen is dismissed.
/*
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController {
    [self.navigationController popViewControllerAnimated:YES];
}
 */


#pragma mark - Sign Up View Controller Delegate
// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:@"Missing Information"
                                    message:@"Make sure you fill out all of the information!"
                                   delegate:nil
                          cancelButtonTitle:@"ok"
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user {
    self.schedules = [[NSMutableArray alloc]init];
    [self.tableView reloadData];
    [self dismissViewControllerAnimated:YES completion:NULL]; // Dismiss the PFSignUpViewController

    
    
    
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error {
    NSLog(@"Failed to sign up...");
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController {
    NSLog(@"User dismissed the signUpViewController");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

# pragma mark - Properties - Lazy Instanstiation
/*
-(NSMutableArray *)schedules{
    if(!_schedules)_schedules = [[NSMutableArray alloc]init];
    return _schedules;
}
 */

/*!
 *  Query Parse to retrieve schedules that current user is a part of
 */
-(void)getMySchedules
{
    PFRelation *relation = [[PFUser currentUser] relationForKey:kUserPropertyGroupSchedules];
    PFQuery *query = [relation query];
    [query orderByAscending:@"endDate"];
    [query includeKey:kGroupSchedulePropertyPersonsInGroup];
    [query includeKey:kGroupSchedulePropertyHomeGame];
    [query includeKey:kGroupSchedulePropertyCreatedBy];
    [query includeKey:[NSString stringWithFormat:@"%@.%@", kGroupSchedulePropertyPersonsInGroup, kPersonPropertyAssociatedUser]];
    
    // Only include this season's schedules
    PFQuery *hgQuery = [PFQuery queryWithClassName:kHomeGameClassName];
    [hgQuery whereKey:kHomeGamePropertyCurrentSeason equalTo:[NSNumber numberWithBool:YES]];
    [query whereKey:kGroupSchedulePropertyHomeGame matchesQuery:hgQuery];
    
    //[self.loadingWheel startAnimating];
    [query findObjectsInBackgroundWithBlock:^(NSArray *schedulesForThisUser, NSError *error) {
        if(!error){
            self.schedules = [[NSMutableArray alloc]initWithCapacity:schedulesForThisUser.count]; //TODO: in v2, compare retreived schedules to current and only update ones that have changed
            if([schedulesForThisUser count] == 0){
                //TODO: update view to say "You are not in any group schedules. Tap the plus button in the top right to create or join one".
                [self.loadingWheel stopAnimating];
                [self.tableView reloadData];
                return;
            }
            NSMutableArray *scheduleIdsToRemove = [[NSMutableArray alloc]init];
            for(PFObject *parseSchedule in schedulesForThisUser){
                Schedule *scheduleObject = [MySchedulesTableViewController createScheduleObjectFromParseInfo:parseSchedule];
                //TODO: maybe figure out better way to check to make sure user has not been removed from schedule. maybe implement callback in above method. note: this is also called in ContainerVC
                if(scheduleObject.currentUserWasRemoved){
                    [scheduleIdsToRemove addObject:scheduleObject.parseObjectID];
                }else{
                    [self addSchedule:scheduleObject];
                }
            }
            if(scheduleIdsToRemove.count > 0){
                [MySchedulesTableViewController removeSchedulesFromCurrentUser:scheduleIdsToRemove];
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Alert" message:@"You have been removed from one or more groups by the group creator." preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                [self presentViewController:alert animated:YES completion:nil];
            }
            [self.loadingWheel stopAnimating];
            [self.tableView reloadData];
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.scrollRow inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
            //[self scrollToCurrentInterval]; why doesn't this work?

        }
        else{
            [self.loadingWheel stopAnimating];
            NSLog(@"error retrieving user's schedules from parse");
            self.schedules = nil;
            [self.tableView reloadData];
            //TODO: update view to say "Error retrieving schedules"
        }
        
    }];
    

}

+(void)removeSchedulesFromCurrentUser:(NSArray *)scheduleIds
{
    PFRelation *relation = [[PFUser currentUser] relationForKey:kUserPropertyGroupSchedules];
    for(NSString *scheduleId in scheduleIds){
        [relation removeObject:[PFObject objectWithoutDataWithClassName:kGroupScheduleClassName objectId:scheduleId]];
    }
    [[PFUser currentUser] saveInBackground]; //TODO: maybe do saveInBackgroundWithBlock
   
}

-(void)addSchedule:(Schedule *)schedule
{
    [self.schedules addObject:schedule];
    //had other things here before but decided to move them
}



+(Schedule *)createScheduleObjectFromParseInfo: (PFObject *)parseSchedule{
    
    NSString *groupName = parseSchedule[kGroupSchedulePropertyGroupName];
    NSString *groupCode = parseSchedule[kGroupSchedulePropertyGroupCode];
    NSDate *startDate = parseSchedule[kGroupSchedulePropertyStartDate];
    NSDate *endDate = parseSchedule[kGroupSchedulePropertyEndDate];
    BOOL assignmentsGenerated = [parseSchedule[kGroupSchedulePropertyAssignmentsGenerated] boolValue];
    NSString *parseObjectID = parseSchedule.objectId;
    
    PFObject *parseHomeGame = parseSchedule[kGroupSchedulePropertyHomeGame];
    NSString *opponent = parseHomeGame[kHomeGamePropertyOpponent];
    NSDate * gameTime = parseHomeGame[kHomeGamePropertyGameTime];
    BOOL isConferenceGame = parseHomeGame[kHomeGamePropertyConferenceGame];
    BOOL isExhibition = parseHomeGame[kHomeGamePropertyExhibition];
    BOOL currentSeason = parseHomeGame[kHomeGamePropertyCurrentSeason];
    HomeGame *homeGame = [[HomeGame alloc]initWithOpponentName:opponent gameTime:gameTime isExhibition:isExhibition isConferenceGame:isConferenceGame currentSeason:currentSeason parseObjectID:parseHomeGame.objectId];
     
    PFObject *creator = parseSchedule[kGroupSchedulePropertyCreatedBy];
     
    NSArray *personsInGroup = parseSchedule[kGroupSchedulePropertyPersonsInGroup];
    //TODO: does this order by CreatedAtAscending?  [query orderByAscending:kParsePropertyCreatedAt];

    NSMutableArray *personsArray = [[NSMutableArray alloc]initWithCapacity:personsInGroup.count];
    BOOL currentUserStillInSchedule = false;
    for(int i = 0; i < personsInGroup.count; i++){
        PFObject *parsePerson = (PFObject *)personsInGroup[i];
        //PFUser *user = parsePerson[kPersonPropertyAssociatedUser];
        PFObject *user = nil;
        NSString *offlineName;
        if(![parsePerson objectForKey: kPersonPropertyAssociatedUser]){
            offlineName = parsePerson[kPersonPropertyOfflineName];
        }else{
            user = parsePerson[kPersonPropertyAssociatedUser];
            if([user.objectId isEqualToString:[[PFUser currentUser] objectId]]) currentUserStillInSchedule = true;
        }
        NSMutableArray *assignmentsArray = parsePerson[kPersonPropertyAssignmentsArray]; //TODO: do i need mutable copy?
        Person *person = [[Person alloc]initWithUser:user assignmentsArray:assignmentsArray scheduleIndex:i  parseObjectID:parsePerson.objectId];
        //OR, scheduleIndex = parseObject[scheduleIndexProperty]; forgot why I decided to store this property on Parse. might not be necessary //should do i so that it stays consistent after removal of people. should not store index on parse (i don't think i should. if i do, then i need to update it everytime i remove people)
        person.offlineName = offlineName;
        [personsArray addObject:person];
    }
    
    
    Schedule *schedule = [[Schedule alloc]initWithGroupName:groupName groupCode:groupCode startDate:startDate endDate:endDate intervalLengthInMinutes:60 personsArray:personsArray homeGame:homeGame createdBy:creator assignmentsGenerated:assignmentsGenerated parseObjectID:parseObjectID] ;
    
    if(!currentUserStillInSchedule){
        schedule.currentUserWasRemoved = true;
    }
    return schedule;
    
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{

    if (!self.schedules | (self.schedules.count == 0)) {
        
        //TODO: display appropriate message
        if(self.loadingWheel.isAnimating){
            UILabel *messageLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                            self.tableView.bounds.size.width,
                                                                            self.tableView.bounds.size.height)];
            self.loadingWheel.center = messageLbl.center;
            [messageLbl addSubview:self.loadingWheel];
            self.tableView.backgroundView = messageLbl;
        }else{
            
            //create a lable size to fit the Table View
            UILabel *messageLbl = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                            self.view.bounds.size.width,
                                                                            self.view.bounds.size.height)];
            //set the message
            messageLbl.text = !self.schedules ? @"Unable to load schedules. Pull down to refresh." : @"Tap the + button in the top right to create or join a schedule. Your schedules will show up here.";
            //center the text
            messageLbl.textAlignment = NSTextAlignmentCenter;
            messageLbl.numberOfLines = 0;
            //auto size the text
            [messageLbl sizeToFit];
            
            //set back to label view
            self.tableView.backgroundView = messageLbl;
            //no separator
            
            

        }
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return 0;
    }else{
        self.tableView.backgroundView = nil;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }
    
    
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    // Return the number of rows in the section.
    return [self.schedules count]; //TODO: what if self.schedules = nil?
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MySchedulesTableViewCell *cell = (MySchedulesTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"My Schedule Cell" forIndexPath:indexPath];
 
    // Configure the cell...
    Schedule *schedule = [self.schedules objectAtIndex:indexPath.row];
    HomeGame *homeGame = schedule.homeGame;
    cell.scheduleNameLabel.text = schedule.groupName;
    cell.opponentLabel.text = homeGame.opponentName;
    cell.gameTimeLabel.text = [[[Constants formatDate:homeGame.gameTime withStyle:NSDateFormatterShortStyle] stringByAppendingString:@" "] stringByAppendingString:[Constants formatTime:homeGame.gameTime withStyle:NSDateFormatterShortStyle]];
    
    if([schedule.startDate timeIntervalSinceNow] < 0){ //schedule has started
        if([homeGame.gameTime timeIntervalSinceNow] < 0 ){//game has happened
            cell.backgroundColor = [UIColor lightGrayColor];
            cell.startDateLabel.text = @"Game Over";
            cell.startDateLabel.textColor = [UIColor blueColor];
        }else{ //game is in progress
            cell.backgroundColor = [UIColor whiteColor];
            cell.startDateLabel.text = @"In Progress";
            cell.startDateLabel.textColor = [UIColor redColor];
        }
    }else { //schedule has not started yet
        
        NSDate *today;
        NSDate *startDay;
        NSCalendar *calendar = [NSCalendar currentCalendar];
        [calendar rangeOfUnit:NSCalendarUnitDay startDate:&today
                     interval:NULL forDate:[NSDate date]];
        [calendar rangeOfUnit:NSCalendarUnitDay startDate:&startDay
                     interval:NULL forDate:schedule.startDate];

        NSDateComponents *components = [calendar components:(NSCalendarUnitDay) fromDate:today toDate:startDay options:0];
        cell.backgroundColor = [UIColor whiteColor];
        cell.startDateLabel.text = components.day == 0 ? @"Schedule Starts today" : [NSString stringWithFormat:@"Schedule Starts in %ld days", (long)components.day];

        cell.startDateLabel.textColor = [UIColor blackColor];
        
    }
 
    return cell;
}


#pragma mark - CallBacks

/*! Called when user chooses to join a schedule and enters the correct password.
 *  Adds user to the schedule, and saves to Parse
 */
-(IBAction)joinedSchedule:(UIStoryboardSegue *)segue
{
    
    PFQuery *query = [PFQuery queryWithClassName:kGroupScheduleClassName];
    //TODO: I could store actual scheduleParseObject in JoinScheduleViewController
    //TODO: Might need to deal with concurrency here
    //TODO: Maybe display loading wheel
    //TODO: deal with errors
    [query getObjectInBackgroundWithId: self.scheduleToJoin.parseObjectID block:^(PFObject *parseSchedule, NSError *error) {
        if(!error){
            NSLog(@"Retrieved schedule to join from parse");
            Person *newPerson = [[Person alloc]initWithUser:[PFUser currentUser] numIntervals:self.scheduleToJoin.numIntervals];
            newPerson.scheduleIndex = self.scheduleToJoin.personsArray.count;
            PFObject *personObject = [PFObject objectWithClassName:kPersonClassName];
            personObject[kPersonPropertyAssignmentsArray] = newPerson.assignmentsArray;
            personObject[kPersonPropertyAssociatedUser] = newPerson.user;

    
            [personObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(!error){
                    NSLog(@"Saved new person object to parse");

                    NSMutableArray *personsArray = (NSMutableArray *)parseSchedule[kGroupSchedulePropertyPersonsInGroup]; //TODO: might need mutable copy
                    [personsArray addObject:personObject];
                    parseSchedule[kGroupSchedulePropertyPersonsInGroup] = (NSArray *)personsArray;
                    
                    [parseSchedule saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                     if(!error){
                         NSLog(@"Saved schedule to join to parse");

                         PFRelation *relation = [[PFUser currentUser] relationForKey:kUserPropertyGroupSchedules];
                         [relation addObject:parseSchedule];
                         [[PFUser currentUser] saveInBackground];
                         
                         [self.scheduleToJoin.personsArray addObject:newPerson];
                         [self addSchedule:self.scheduleToJoin];
                         [self.tableView reloadData];
                     }
                 }];
                }
            }];
        }
    }];
    
}


/*!
 *  Called when user chooses to create a schedule.
 *  Creates the schedule, and saves to Parse
 */
-(IBAction)createSchedule:(UIStoryboardSegue *)segue
{
    //Schedule should implement copy protocol
    //Schedule *newSchedule = [self.scheduleToAdd copy];
    //[self.schedules addObject:newSchedule];
    //self.scheduleToAdd = nil;
    
    //Note: probably shouldn't update UI until after save success. b/c otherwise user will think they created the schedule, but it won't show up on other's phones
    
    
    //TODO: similar to join schedule todo's
    Schedule *newSchedule = self.scheduleToAdd;
    
    PFObject *scheduleObject = [PFObject objectWithClassName:kGroupScheduleClassName];
    scheduleObject[kGroupSchedulePropertyGroupName ] = newSchedule.groupName;
    scheduleObject[kGroupSchedulePropertyGroupCode] = newSchedule.groupCode;
    scheduleObject[kGroupSchedulePropertyStartDate] = newSchedule.startDate;
    scheduleObject[kGroupSchedulePropertyEndDate] = newSchedule.endDate;
    PFObject *homeGame = [PFObject objectWithoutDataWithClassName:kHomeGameClassName objectId:newSchedule.homeGame.parseObjectID];
    scheduleObject[kGroupSchedulePropertyHomeGame] = homeGame;
    scheduleObject[kGroupSchedulePropertyCreatedBy] = [PFUser currentUser];
    
    scheduleObject[kGroupSchedulePropertyAssignmentsGenerated] = [NSNumber numberWithBool:false];

    
    
   
    Person *person = [[Person alloc]initWithUser:[PFUser currentUser] numIntervals:self.scheduleToAdd.numIntervals];
    PFObject *personObject = [PFObject objectWithClassName:kPersonClassName];
    personObject[kPersonPropertyAssignmentsArray] = person.assignmentsArray;
    personObject[kPersonPropertyAssociatedUser] = person.user;
    
    /*
    [personObject saveInBackground];
    
    NSArray *personsArray = @[[PFObject objectWithoutDataWithClassName:kPersonClassName objectId:personObject.objectId]];
    scheduleObject[kGroupSchedulePropertyPersonsInGroup] = personsArray;
    
    [scheduleObject saveInBackground];
    
    PFRelation *userRelation = [[PFUser currentUser] relationForKey:kUserPropertyGroupSchedules];
    [userRelation addObject:[PFObject objectWithoutDataWithClassName:kGroupScheduleClassName objectId:scheduleObject.objectId]];
    [[PFUser currentUser] saveInBackground];
     */
    
    //TODO: do i need to do all of these separately or can I do them at the same time?check when objectID gets initialized
    [personObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if(!error){
            
            person.assignmentsArray = personObject[kPersonPropertyAssignmentsArray];
            person.parseObjectID = personObject.objectId;
            person.scheduleIndex = 0;
            NSMutableArray *personsArray = [[NSMutableArray alloc]initWithArray:@[person]];
            newSchedule.personsArray = personsArray;
            [newSchedule createIntervalDataArrays];
            NSArray *parsePersonsArray = @[personObject];
            scheduleObject[kGroupSchedulePropertyPersonsInGroup] = parsePersonsArray;
            
            [scheduleObject saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if(!error){
                    newSchedule.parseObjectID = scheduleObject.objectId;
                    PFRelation *userRelation = [[PFUser currentUser] relationForKey:kUserPropertyGroupSchedules];
                    [userRelation addObject:scheduleObject];
                    [[PFUser currentUser] saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if(!error){
                            [self addSchedule:newSchedule];
                            [self.tableView reloadData];

                        }
                    }];
                }
            }];
        }
    }];
    
     
}
-(IBAction)didPressLogOut:(UIStoryboardSegue *)segue
{
    [PFUser logOut];
    [self displayLoginAndSignUpViews];
}
-(IBAction)closeSettings:(UIStoryboardSegue *)segue
{
    
}
-(IBAction)scheduleDeleted:(UIStoryboardSegue *)segue
{
    [self refreshSchedules];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if([[segue destinationViewController] isKindOfClass:[MyScheduleContainerViewController class]]){
        if([sender isKindOfClass:[UITableViewCell class]]){
            MyScheduleContainerViewController *mscvc = [segue destinationViewController];
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            if(indexPath){
                //TODO: Note: because this is in an array, it is pass by reference. so i don't really need to notify this view controller. probably still should, and maybe should pass this as a mutable copy to prevent coupling across vcs (even though in effect i want coupling)
                //this also means a workaround could probably be to put all self.schedules in an array
                //but i should use notifications so i know when to update ui
                Schedule *schedule = self.schedules[indexPath.row];
                mscvc.schedule = schedule;
            }
        }
    }
    else if([[segue destinationViewController] isKindOfClass:[NewScheduleTableViewController class]]){
        if(sender==self.addScheduleButton){
            NewScheduleTableViewController *nstvc = [segue destinationViewController];
            nstvc.mySchedulesHomeGameParseIds = [self mySchedulesHomeGameParseIds];
    
        }
    }
}

-(NSMutableSet *)mySchedulesHomeGameParseIds
{
    NSMutableSet *set = [[NSMutableSet alloc]initWithCapacity:self.schedules.count];
    for(Schedule *schedule in self.schedules){
        HomeGame *hg = schedule.homeGame;
        [set addObject:hg.parseObjectID];
    }
    return set;
}



@end
