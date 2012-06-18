//
//  NewLogEntryCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogEntryCell.h"
#import "HPGrowingTextView.h"

@interface NewLogEntryCell : LogEntryCell

@property (nonatomic, assign) IBOutlet HPGrowingTextView *logTextView;

@end
