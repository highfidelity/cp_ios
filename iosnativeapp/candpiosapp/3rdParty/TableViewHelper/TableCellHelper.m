//
//  TableCellHelper.m
//
//  Created by David Mojdehi on 3/10/11.
//  Copyright 2011 Mindful Bear Apps. All rights reserved.
//

#import "TableCellHelper.h"



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellGroup
@synthesize cellConfigs;
@synthesize headerText, footerText, footerView;
-(id)init
{
	if((self = [super init]))
	{
		cellConfigs = [[NSMutableArray alloc]init];
	}
	return self;
}
-(id)initWithCells:(NSArray *)cellConfigsArg
{
	if((self = [super init]))
	{
		cellConfigs = [cellConfigsArg mutableCopy];
	}
	return self;
}


-(void)addCell:(TableCellHelper *)cell
{
	[cellConfigs addObject:cell];
}
@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface TableCellHelper(Internal)
-(UITableViewCell*)makeCellCommon:(UITableView*)tableView;
-(id)getKvoValue;
-(void)setKvoValue:(id)val;
@end
@implementation TableCellHelper
@synthesize keyName, customKeyObject;
@synthesize labelText, labelFont;
@synthesize detailText, detailFont;
@synthesize imageNamed;

-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey
{
	self = [super init];
	if(self)
	{
		labelText = [label copy];
		customKeyObject = kvoObj;
		keyName = [kvoKey copy];
	}
	return self;
}

-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	return nil;
}

-(UITableViewCell*)makeCellCommon:(UITableView*)tableView
{
	static NSString *CellIdentifier = @"StyleCustomizationCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
	}
	
	// setup the default text values
	cell.textLabel.text = labelText;
	if(labelFont)
		cell.textLabel.font = labelFont;
	if(detailText)
		cell.detailTextLabel.text = detailText;
	if(detailFont)
		cell.detailTextLabel.font= detailFont;
	if(imageNamed)
		cell.imageView.image = [UIImage imageNamed:imageNamed];

	// most cells can't be selected
	cell.selectionStyle = UITableViewCellSelectionStyleNone;

	cell.accessoryView = nil;
	
	return cell;
	
}
-(bool)hasCustomHeight
{
	return  false;
}
-(CGFloat)calculateCustomHeightForCellWidth:(CGFloat)width
{
	return 44.0;
}

-(HelperSelectedBlock)selectionAction
{
	return mSelectionAction;
}
-(void)setSelectionAction:(HelperSelectedBlock)action
{
	mSelectionAction = [action copy];
						
}
-(id)getKvoValue
{
	id val = nil;
	if(customKeyObject && keyName)
	{
        val = [customKeyObject valueForKeyPath:keyName]; 
	}
	return val;
}

-(void)setKvoValue:(id)val
{
	// find what we need to set
	if(customKeyObject && keyName)
	{
		@try {
			[customKeyObject setValue:val forKeyPath:keyName]; 
		}
		@catch (NSException *exception) {
#if DEBUG
			NSLog(@"Exception while setting value of %@, exception name: %@, reason:%@", keyName, exception.name, exception.reason);
#endif
		}
	}
	
}

@end

//////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellText
@synthesize text;
@synthesize textFont;

-(id)initWithText:(NSString *)textArg
{
	if((self = [super initWithLabel:nil  kvoObject:nil kvoKeyName:nil]))
	{
		text = [textArg copy];
		textFont = [UIFont systemFontOfSize:18.0];
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	static NSString *CellIdentifier = @"StyleTextCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) {
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
		cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
		cell.textLabel.numberOfLines = 0;
		//cell.textLabel.numberOfLines = numberOfLines;
	}

	//	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	cell.textLabel.text = text;
	cell.textLabel.font = textFont;
	cell.selectionStyle = UITableViewCellSelectionStyleNone;
	
	// also give a chance to the initial setup blocks
	
	return cell;
}

/////////////
// override base class to provide our custom height
-(bool)hasCustomHeight
{
	return true;
}

-(CGFloat)calculateCustomHeightForCellWidth:(CGFloat)width
{
	CGSize detail_size = [text sizeWithFont:textFont
							constrainedToSize:CGSizeMake(width, 4000)
								lineBreakMode:UILineBreakModeWordWrap];
	
	// add an extra line of padding, too
	CGFloat totalHeight = detail_size.height + textFont.lineHeight;
	return totalHeight;
	
}
@end

@implementation TableCellTextLabel

@synthesize text;
@synthesize textFont;
-(id)initWithLabel:(NSString *)label andText:(NSString *)textArg
{
	if((self = [super initWithLabel:label kvoObject:nil kvoKeyName:nil]))
	{
		text = [textArg copy];
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(140, 0, 130, 30)];
	//UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(170, 0, 100, 30)] autorelease];
	label.text = [text copy];
	label.font = [textFont copy];
	cell.accessoryView = label;
	
	return cell;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellSwitch
@synthesize switchChanged;
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey;
{
	self = [super initWithLabel:label kvoObject:kvoObj kvoKeyName:kvoKey];
	if(self)
	{
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	UISwitch *mySwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
	mySwitch.on = [[self getKvoValue] boolValue];
	[mySwitch addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
	
	cell.accessoryView = mySwitch;
	
	// also give a chance to the initial setup blocks
	
	return cell;
}

-(void)switchValueChanged:(id)sender
{
    UISwitch *swtch = (UISwitch*)sender;

    [self setKvoValue:[NSNumber numberWithBool:swtch.on]];
	if(switchChanged)
		switchChanged(self);
}


@end 

////////////////////////////////////////////////////////////
@implementation TableCellProgress
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey
{
	self = [super initWithLabel:label kvoObject:kvoObj kvoKeyName:kvoKey];
	if(self)
	{
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	UIProgressView *slider = [[UIProgressView alloc] initWithFrame:CGRectMake(170, 0, 100, 30)];
	
	
	slider.progress = [[self getKvoValue] doubleValue];
	//slider.tag = (NSInteger) cellConfig;
	
	cell.accessoryView = slider;
	
	
	// also, update the text field
	// for sliders with values in their title
	//		e.g. (FontSize (%d):  <----slider---->
	//[self updateSliderText];
	
	return cell;
}


@end

////////////////////////////////////////////////////////////
@implementation TableCellSlider
@synthesize minValue, maxValue;
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey minValue:(double)minValueArg maxValue:(double)maxValueArg
{
	self = [super initWithLabel:label kvoObject:kvoObj kvoKeyName:kvoKey];
	if(self)
	{
		minValue = minValueArg;
		maxValue = maxValueArg;
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(170, 0, 100, 30)];
		
	slider.minimumValue = minValue;
	slider.maximumValue = maxValue;
	
	slider.value = [[self getKvoValue] doubleValue];
	//slider.tag = (NSInteger) cellConfig;
	[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
	
	cell.accessoryView = slider;
	
	
	// also, update the text field
	// for sliders with values in their title
	//		e.g. (FontSize (%d):  <----slider---->
	//[self updateSliderText];
	
	return cell;
}

-(void)updateSliderText
{
//	NSString *labelTitle = self.labelText
//	NSString *labelFormat = [cellConfig objectForKey:kSliderLabelFormatKey];
//	if(labelFormat)
//		self.textLabel.text = [NSString stringWithFormat:labelFormat, val ];
//	else
//		self.textLabel.text = labelTitle;
	
}

-(void)sliderValueChanged:(id)sender
{
    UISlider *slider = (UISlider*)sender;
	
	
	
	// save the value to the settings
	double valueForSettings = slider.value;
	[self setKvoValue:[NSNumber numberWithDouble:valueForSettings]];
	
	// also, update the text field
	if(mSliderChanged)
		mSliderChanged(self);
	//[self updateSliderText];
	
}

-(HelperActionBlock) sliderChanged
{
	return mSliderChanged;
}
-(void)setSliderChanged:(HelperActionBlock)block
{
	mSliderChanged = [block copy];
}
@end 



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellRadioButton
@synthesize checkedValue, changeInvalidatesWholeTable;
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey kvoCheckedValue:(NSObject*)checkedValueArg
{
	self = [super initWithLabel:label kvoObject:kvoObj kvoKeyName:kvoKey];
	if(self)
	{
		changeInvalidatesWholeTable = false;
#if DEBUG
		// ensure that the kvo source supports comparisons
		if(kvoObj && kvoKey)
		{
			if(![[kvoObj valueForKeyPath:kvoKey] respondsToSelector:@selector(compare:)])
			{
				// error!
				assert(!"Kvo field must support the 'compare:' message!");
			}
		}
#endif
		checkedValue = checkedValueArg;
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];

	// should we be checked?  compare our values
	NSObject *currentValue = [self getKvoValue];
	bool checked = false;
	if(!currentValue && !checkedValue)
	{
		checked = true;
	}
	else if (currentValue && checkedValue)
	{
		if([((NSNumber*)currentValue) compare: (NSNumber*)checkedValue] == NSOrderedSame)
			checked = true;
	}
		
	cell.accessoryView = nil;
	if( checked )
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	else
		cell.accessoryType = UITableViewCellAccessoryNone;
	
	__unsafe_unretained TableCellRadioButton *selfNotRetained = self;
	[self setSelectionAction:^(TableCellHelper* cellConfig, UITableView *tableView, NSIndexPath *indexPath) {

		// we get here when we've been selected; so apply our changes now
		[selfNotRetained setKvoValue:selfNotRetained.checkedValue];
		
		// refresh the current group (to redraw any sibling checks)
		if(selfNotRetained.changeInvalidatesWholeTable)
		{
			[tableView reloadData];
		}
		else
		{
			[tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]  withRowAnimation:UITableViewRowAnimationNone ];
		}

	}];
	return cell;
}

-(void)updateViewFromSource
{
	
}
@end 




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellTextField
@synthesize placeholderText,secureTextEntry;
-(id)initWithLabel:(NSString *)label placeholderText:(NSString *)placeholderTextArg kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey
{
	self = [super initWithLabel:label kvoObject:kvoObj kvoKeyName:kvoKey];
	if(self)
	{
		placeholderText = [placeholderTextArg copy];
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(110, 10, 185, 30)];
	textField.adjustsFontSizeToFitWidth = YES;
	textField.textColor = [UIColor blackColor];
	textField.placeholder = self.placeholderText;
	if(secureTextEntry)
		textField.secureTextEntry = YES;
	// try to set the text!
		
	textField.text = [self getKvoValue];
	
	// an email address? use the email
	if([placeholderText rangeOfString:@"@"].length > 0)
		textField.keyboardType = UIKeyboardTypeEmailAddress;
	
	textField.delegate = self;
	cell.accessoryView = textField;
	
	// also give a chance to the initial setup blocks
	if(mTextFieldWillChangeBlock)
		mTextFieldWillChangeBlock(textField);

	return cell;
}

// return NO to not change text
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string;
{
	BOOL allowChange = YES;
	if(mTextFieldWillChangeBlock)
	{
		allowChange = mTextFieldWillChangeBlock(textField);
	}
	return allowChange;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField 
{
	// TODO apply our change to the kvo target!
    //[inputTexts replaceObjectAtIndex:textField.tag withObject:textField.text];
	[self setKvoValue:textField.text ];
	
	if(mTextFieldDidCommitBlock)
	{
		mTextFieldDidCommitBlock(textField);
	}
    return YES;
}
-(void)setTextFieldWillChange:(TextFieldWillChangeBlock)textFieldWillChange
{
	mTextFieldWillChangeBlock = [textFieldWillChange copy];
}
-(TextFieldWillChangeBlock)textFieldWillChange
{
	return mTextFieldWillChangeBlock;
}
-(void)setTextFieldDidCommit:(TextFieldDidCommitBlock)textFieldDidChange
{
	mTextFieldDidCommitBlock = [textFieldDidChange copy];
}
-(TextFieldDidCommitBlock)textFieldDidCommit
{
	return mTextFieldDidCommitBlock;
}
@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellButton
@synthesize buttonText, buttonAction;
-(id)initWithLabel:(NSString *)label buttonText:(NSString*)buttonTextArg action:(HelperActionBlock)block;
{
	self =[super initWithLabel:label kvoObject:nil kvoKeyName:nil];
	if(self)
	{
		buttonAction = [block copy];
		buttonText = [buttonTextArg copy];
	}
	return self;
}

-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	
	UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
	[button setFrame:CGRectMake(200, 3, 100, 28)];

	[button setTitle:buttonText forState:UIControlStateNormal];
	[button setTitle:buttonText forState:UIControlStateHighlighted];
	[button setTitle:buttonText forState:UIControlStateDisabled];
	[button setTitle:buttonText forState:UIControlStateSelected];

	[button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
	
	cell.accessoryView = button;
	
	
	return cell;
}

-(void)buttonPressed:(id)sender
{
    
	if(buttonAction)
		buttonAction(self);    
}


@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation TableCellAction
@synthesize accessoryType;
-(id)initWithLabel:(NSString *)label accessory:(UITableViewCellAccessoryType)accessoryTypeArg action:(HelperActionBlock)block
{
	self =[super initWithLabel:label kvoObject:nil kvoKeyName:nil];
	if(self)
	{
		self.selectionAction = [block copy];
		accessoryType = accessoryTypeArg;
	}
	return self;
}
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView
{
	UITableViewCell *cell = [self makeCellCommon:tableView];
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

	return cell;
}

@end


