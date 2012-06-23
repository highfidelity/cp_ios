//
//  NewLogEntryCell.h
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "LogBaseEntryCell.h"
#import "HPGrowingTextView.h"

@interface LogNewEntryCell : LogBaseEntryCell

@property (nonatomic, assign) IBOutlet HPGrowingTextView *logTextView;

@end
