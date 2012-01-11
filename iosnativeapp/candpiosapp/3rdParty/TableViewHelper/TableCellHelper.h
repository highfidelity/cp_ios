//
//  TableCellHelper.h
//
//  Created by David Mojdehi on 3/10/11.
//  Copyright 2011 Mindful Bear Apps LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


@class TableCellHelper;

typedef void (^ButtonActionBlock)(NSDictionary* cellConfig);
typedef void (^HelperActionBlock)(TableCellHelper* cellConfig);
typedef void (^HelperSelectedBlock)(TableCellHelper* cellConfig, UITableView *tableView, NSIndexPath *indexPath );
typedef BOOL (^TextFieldWillChangeBlock)(UITextField *textField);
typedef void (^TextFieldDidCommitBlock)(UITextField *textField);

//@interface CustomCell
@interface UITableViewCell(AccessoryHelper)
+(UITableViewCell*) makeNewCellInView:(UITableView*)tableView withConfig:(NSMutableDictionary*)cellConfig andKvcDataSource:(id)kvcDataSource;
//+(UITableViewCell*) makeAccessoryViewWithConfig:(NSMutableDictionary*)cellConfig andKvcDataSource:(id)kvcDataSource;
@end


////////////////////////////////////////////////////////////
@interface TableCellGroup : NSObject
@property (nonatomic, strong) NSMutableArray *cellConfigs;
@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, copy) NSString *footerText;
@property (nonatomic, strong) UIView *footerView;
-(id)init;
-(id)initWithCells:(NSArray*)cellConfigs;
-(void)addCell:(TableCellHelper*)cell;
@end


////////////////////////////////////////////////////////////
@interface TableCellHelper : NSObject
{
	HelperSelectedBlock mSelectionAction;
}
@property (nonatomic, copy) NSString *labelText;
@property (nonatomic, strong) UIFont *labelFont;
@property (nonatomic, copy) NSString *detailText; // only available on some cells
@property (nonatomic, strong) UIFont *detailFont;
@property (nonatomic, copy) NSString *imageNamed; // only available on some cells
@property (nonatomic, readonly) bool hasCustomHeight;

@property (nonatomic, copy) NSString *keyName;
@property (nonatomic, strong) NSObject *customKeyObject;
@property (nonatomic, copy) HelperSelectedBlock selectionAction;

-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey;
-(UITableViewCell*) makeNewCellInView:(UITableView*)tableView;
-(CGFloat)calculateCustomHeightForCellWidth:(CGFloat)width;
@end


////////////////////////////////////////////////////////////
////////////////////////////// Value cells
// a multi-line text field
@interface TableCellText : TableCellHelper
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *textFont;
-(id)initWithText:(NSString *)text;
@end 

////////////////////////////////////////////////////////////
// a small text label & short one-line text
@interface TableCellTextLabel : TableCellHelper
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIFont *textFont;
-(id)initWithLabel:(NSString *)label andText:(NSString *)text;
@end 



////////////////////////////////////////////////////////////
@interface TableCellSwitch : TableCellHelper
@property (nonatomic, copy) HelperActionBlock switchChanged;
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey;
@end 

////////////////////////////////////////////////////////////
@interface TableCellSlider : TableCellHelper
{
	HelperActionBlock mSliderChanged;
}
@property (nonatomic, copy) HelperActionBlock sliderChanged;
@property (nonatomic, assign) double minValue;
@property (nonatomic, assign) double maxValue;
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey minValue:(double)minValue maxValue:(double)maxValue;
@end 

////////////////////////////////////////////////////////////
@interface TableCellProgress : TableCellHelper
{
}
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey;
@end 

////////////////////////////////////////////////////////////
@interface TableCellRadioButton : TableCellHelper< UITextFieldDelegate >
@property (nonatomic, strong) NSObject *checkedValue;
@property (nonatomic, assign) bool changeInvalidatesWholeTable;
-(id)initWithLabel:(NSString *)label kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey kvoCheckedValue:(NSObject*)checkedValue;
@end 

////////////////////////////////////////////////////////////
@interface TableCellTextField : TableCellHelper< UITextFieldDelegate >
{
	TextFieldWillChangeBlock mTextFieldWillChangeBlock;
	TextFieldDidCommitBlock mTextFieldDidCommitBlock;
}
@property (nonatomic, copy) NSString *placeholderText;
@property (nonatomic, copy) TextFieldWillChangeBlock textFieldWillChange;
@property (nonatomic, copy) TextFieldDidCommitBlock textFieldDidCommit;
-(id)initWithLabel:(NSString *)label placeholderText:(NSString *)placeholderTextArg kvoObject:(NSObject*)kvoObj kvoKeyName:(NSString*)kvoKey;
@end


////////////////////////////////////////////////////////////
////////////////////////////// Action cells


////////////////////////////////////////////////////////////
@interface TableCellButton : TableCellHelper
@property (nonatomic, copy) NSString *buttonText;
@property (nonatomic, copy) HelperActionBlock buttonAction;

-(id)initWithLabel:(NSString *)label buttonText:(NSString*)buttonTextArg action:(HelperActionBlock)block;
@end

////////////////////////////////////////////////////////////
@interface TableCellAction : TableCellHelper
@property (nonatomic, assign) UITableViewCellAccessoryType accessoryType;
-(id)initWithLabel:(NSString *)label accessory:(UITableViewCellAccessoryType)accessoryType action:(HelperActionBlock)block;
@end

