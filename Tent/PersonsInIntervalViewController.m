//
//  PersonsInIntervalViewController.m
//  Tent
//
//  Created by Shrek on 7/31/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import "PersonsInIntervalViewController.h"

@interface PersonsInIntervalViewController ()

@end

@implementation PersonsInIntervalViewController


@synthesize people = _people;
- (void)setPeople:(NSMutableArray *)people
{
    _people = people;
    [self.tableView reloadData];
}
- (NSMutableArray *)people
{
    if(!_people) _people = [[NSMutableArray alloc]init];
    return _people;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
