//
//  ChatMessageCell.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/29.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#define CHAT_LABEL_TAG    324
#define BUBBLE_TOP_TAG    823
#define BUBBLE_MIDDLE_TAG 953
#define BUBBLE_BOTTOM_TAG 382
#define TIMESTAMP_TAG     720

@interface ChatMessageCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImage;

@end
