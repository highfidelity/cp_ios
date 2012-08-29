//
//  SkillsTableViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 5/23/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SkillsTableViewController.h"
#import "CPSkill.h"

#define SWITCH_TAG 5423

@interface SkillsTableViewController ()

@property (strong, nonatomic) NSOperationQueue *skillQueue;
@property (nonatomic) int visibleCount;
@property (nonatomic) BOOL dataLoaded;

@end

@implementation SkillsTableViewController

- (NSOperationQueue *)skillQueue
{
    if (!_skillQueue) {
        _skillQueue = [NSOperationQueue new];
        _skillQueue.maxConcurrentOperationCount = 1;
    }
    return _skillQueue;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorColor = [UIColor colorWithR:68 G:68 B:68 A:1];

    // check if we have any user skills
    // this will always be the case as for right now we aren't syncing with NSUserDefaults
    if (!self.skills) {
        // show a loading HUD
        [SVProgressHUD showWithStatus:@"Loading Skills..."];

        [CPapi getSkillsForUser:nil completion:^(NSDictionary *json, NSError *error){
            // make sure we don't have a json parse error
            if (!error) {
                // check for an error in the response
                if (![[json objectForKey:@"error"] boolValue]) {
                    // we've recieved an array of skills

                    // create an NSMutableArray of skills for us to hold skills
                    self.skills = [NSMutableArray array];

                    // enumerate through the skills that have come back and create CPSkill Objects
                    // put those in the array
                    for (NSDictionary *skillDict in [json objectForKey:@"payload"]) {
                        [self.skills addObject:[[CPSkill alloc] initFromDictionary:skillDict]];
                    }

                    self.dataLoaded = YES;
                    // upload the tableView with the new data
                    [self.tableView reloadData];

                    // get rid of the SVProgressHud
                    [SVProgressHUD dismiss];
                } else {
                    [SVProgressHUD showErrorWithStatus:[json objectForKey:@"payload"] duration:kDefaultDismissDelay];
                }
            } else {
                [SVProgressHUD showErrorWithStatus:[error localizedDescription] duration:kDefaultDismissDelay];
            }
        }];
    }

}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.skills.count == 0 && self.dataLoaded) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        return 1;
    }

    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    return self.skills.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.skills.count == 0 && self.dataLoaded) {
        return [tableView dequeueReusableCellWithIdentifier:@"HelperTextCell"];
    }
    static NSString *CellIdentifier = @"SkillToggleCell";

    // grab a cell
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    CPSkill *skill = [self.skills objectAtIndex:(NSUInteger) indexPath.row];

    // set our textLabel to the skill name
    cell.textLabel.text = skill.name;

    // add a switch to this cell to show if the skill is visible or not
    UISwitch *visibleSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(231, 8, 79, 27)];
    visibleSwitch.onTintColor = [UIColor colorWithR:56 G:145 B:143 A:1];

    // set the state of the on/off switch
    visibleSwitch.on = skill.isVisible;

    // if this switch is on then add one to the visible count
    if (visibleSwitch.on) {
        self.visibleCount += 1;
    }

    visibleSwitch.tag = SWITCH_TAG;

    // add the target for the switch
    [visibleSwitch addTarget:self action:@selector(toggleVisibility:) forControlEvents:UIControlEventValueChanged];

    // add the switch to the cell
    [cell.contentView addSubview:visibleSwitch];

    return cell;
}

- (IBAction)toggleVisibility:(id)sender
{
    // check if the switch is now on or off
    UISwitch *visibilitySwitch = (UISwitch *)sender;

    // let's grab the ID for the skill related to this switch
    NSIndexPath *cellPath = [self.tableView indexPathForCell:(UITableViewCell *)[[visibilitySwitch superview] superview]];

    // get the skill that this switch is for
    CPSkill __block *skill = [self.skills objectAtIndex:(NSUInteger) cellPath.row];

    // if the switch is now on let's make sure we won't have more than 5
    if (visibilitySwitch.on) {

        if (self.visibleCount == 5) {
            // turn the switch off and show the HUD error
            visibilitySwitch.on = NO;
            [SVProgressHUD showErrorWithStatus:@"You can't have more than 5 visible skills at one time!" duration:kDefaultDismissDelay];

            // return from this function ... nothing else to do here
            return;
        } else {
            // add one to the visible count
            self.visibleCount += 1;
        }
    } else {
        // this was just switched off so decrease our count
        self.visibleCount -= 1;
    }

    NSString *skillName = [self.tableView cellForRowAtIndexPath:cellPath].textLabel.text;
    NSString __block *errorMessage = [NSString stringWithFormat:@"There was a problem modifiying %@.\nPlease try again!", skillName];

    // TODO: we need error handling here
    // send off a request to activate or deactivate
    [CPapi changeSkillStateForSkillWithId:skill.skillID visible:visibilitySwitch.on skillQueue:self.skillQueue completion:^(NSDictionary *json, NSError *error) {
        // make sure the backend has confirmed that we should change state
        if (!error) {
            if ([[json objectForKey:@"error"] boolValue]) {

                // use the above errorMessage if we didn't get one back in the json
                if ([[json objectForKey:@"payload"] isKindOfClass:[NSNull class]]) {
                    errorMessage = [json objectForKey:@"payload"];
                }

                // handle the error
                [self handleErrorForSwitch:visibilitySwitch errorMessage:errorMessage];
            } else {
                // everything's good here so update the info for the skill in our array
                skill.isVisible = visibilitySwitch.on;
            }
        } else {
            [self handleErrorForSwitch:visibilitySwitch errorMessage:errorMessage];
        }
    }];
}

- (void)handleErrorForSwitch:(UISwitch *)erroredSwitch errorMessage:(NSString *)errorMessage
{
    // fix the count visible skills
    self.visibleCount += erroredSwitch.on ? -1 : 1;
    // toggle the switch back to the other state
    erroredSwitch.on = !erroredSwitch.on;

    // show an error with the progress HUD
    [SVProgressHUD showErrorWithStatus:errorMessage duration:kDefaultDismissDelay];
}


@end
