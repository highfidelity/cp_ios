//
//  TableViewControllerHelper.m
//  TableCellHelper
//
//  Created by David Mojdehi on 10/18/11.
//  Copyright 2011 Mindful Bear Apps. All rights reserved.
//

#import "TableViewControllerHelper.h"
#import "TableCellHelper.h"

@implementation TableViewControllerHelper
@synthesize cellConfigs;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
		cellConfigs = [[NSMutableArray alloc]init ];

    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
		cellConfigs = [[NSMutableArray alloc]init ];

    }
    return self;
}

-(void)awakeFromNib
{
	cellConfigs = [[NSMutableArray alloc]init ];
	
	[super awakeFromNib];

}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [cellConfigs count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
	TableCellGroup *group = [cellConfigs objectAtIndex:section ];
	return [group.cellConfigs count];
}



//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fixed font style. use custom view (UILabel) if you want something different
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	
	TableCellGroup *group = [cellConfigs objectAtIndex:section ];
	return group.headerText;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
	TableCellGroup *group = [cellConfigs objectAtIndex:section ];
	return group.footerText;
}

- (UIView *) tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
	TableCellGroup *group = [cellConfigs objectAtIndex:section ];
	if(group.footerView)
	{
		// we can make sure it's centered too
		return group.footerView;
//		headerView = [[UIView alloc] initWithNibName:@"ContactHeaderDetail" bundle:nil];
//		//  headerView = [[UIView alloc] initWithNibName:@"ContactHeaderDetail" bundle:nil];
//		return headerView;
		
	}else{
		return nil;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
	CGFloat height = 0;
	TableCellGroup *group = [cellConfigs objectAtIndex:section ];
	if(group.footerView)
	{
		height = 44.0 + 20.0;
		//height = group.footerView.frame.size.height;
	}
	else if(group.footerText)
	{
		height = 22.0;
	}

	return height;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	
	UITableViewCell *cell = nil;
	// Configure the cell...
    NSObject *groupConfigObj = [cellConfigs objectAtIndex:indexPath.section];
	
	TableCellGroup *group = (TableCellGroup*)groupConfigObj;
	TableCellHelper *cellConfigHelper = [group.cellConfigs objectAtIndex:indexPath.row ];
	cell = [cellConfigHelper makeNewCellInView:tableView];
		
		// if we have a seleciton action, 
//		if(cellConfigHelper.selectionAction)
//			cell.selectionStyle = UITableViewCellSelectionStyleBlue;

	
    return cell;
	
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{

	TableCellGroup *group = [cellConfigs objectAtIndex:indexPath.section];
	TableCellHelper *cellConfig = [group.cellConfigs objectAtIndex:indexPath.row ];

	CGFloat height = 44;
	if(cellConfig.hasCustomHeight)
	{
		CGRect frame = [UIScreen mainScreen].bounds;
		CGFloat width = frame.size.width - 40.0;
		// give the cell a chance to calculate it's height
		height = [cellConfig calculateCustomHeightForCellWidth:width];
	}

    return height;
	
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
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

#pragma mark - Table view delegate


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// perform the action for this cell, if any
	
	// is there a value to change, change it
	// is there an action block?  perform it
	TableCellGroup *group = [cellConfigs objectAtIndex:indexPath.section ];
	TableCellHelper *helper = [ group.cellConfigs objectAtIndex:indexPath.row];
	if(helper.selectionAction)
	{
		helper.selectionAction(helper, self.tableView, indexPath);
	}
	
}


@end
