//
//  FeedViewController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 6/12/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "FeedViewController.h"
#import "CPPost.h"
#import "PostUpdateCell.h"
#import "NewPostCell.h"
#import "PostLoveCell.h"
#import "UserProfileViewController.h"
#import "SVPullToRefresh.h"
#import "CPUserAction.h"
#import "PillPopoverViewController.h"
#import "CommentCell.h"
#import "CPUserDefaultsHandler.h"

#define kMaxFeedLength 140
#define MAX_PREVIEW_POST_COUNT 3
#define AUTO_ACTIVE_FEED_COUNT 3

typedef enum {
    FeedVCStateDefault,
    FeedVCStateReloadingFeed,
    FeedVCStateAddingOrRemovingPendingPost,
    FeedVCStateSentNewPost
} FeedVCState;

typedef enum {
    FeedBGContainerPositionTop,
    FeedBGContainerPositionMiddle,
    FeedBGContainerPositionBottom
} FeedBGContainerPosition;

@interface FeedViewController () <HPGrowingTextViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) CPPost *pendingPost;
@property (strong, nonatomic) NewPostCell *pendingPostCell;
@property (strong, nonatomic) UIView *keyboardBackground;
@property (strong, nonatomic) UITextView *fakeTextView;
@property (nonatomic) FeedVCState currentState;
@property (nonatomic) BOOL previewPostableFeedsOnly;
@property (nonatomic) float newEditableCellHeight;

@end

@implementation FeedViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // subscribe to the applicationDidBecomeActive notification
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleTableViewState) name:@"applicationDidBecomeActive" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newFeedVenueAdded:) name:@"feedVenueAdded" object:nil];

    [self reloadFeedPreviewVenues];

    [self.tableView addPullToRefreshWithActionHandler:^{
        [self getVenueFeedOrFeedPreviews];
    }];
    
    [self toggleTableViewState];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // remove the two views we added to the window
    [self.keyboardBackground removeFromSuperview];

    // unsubscribe from the applicationDidBecomeActive notification
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reloadFeedPreviewVenues];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // dismiss our progress HUD if it's up
    [SVProgressHUD dismiss];
    
    if (self.pendingPost) {
        // if we have a pending post
        // make sure the keyboard isn't up anymore
        [self cancelPost:nil];
    }
}

- (void)setSelectedVenueFeed:(CPVenueFeed *)selectedVenueFeed
{
    if (![_selectedVenueFeed isEqual:selectedVenueFeed]) {
        _selectedVenueFeed = selectedVenueFeed;        
    }
    
    [self toggleTableViewState];
}

- (NSMutableArray *)venueFeedPreviews
{
    if (!_venueFeedPreviews) {
        _venueFeedPreviews = [NSMutableArray array];
    }
    return _venueFeedPreviews;
}

#pragma mark - Table view helper methods

#define MIN_CELL_HEIGHT 38
#define LABEL_BOTTOM_MARGIN 17
#define LAST_PREVIEW_POST_MIN_CELL_HEIGHT 27
#define LAST_PREVIEW_POST_LABEL_BOTTOM_MARGIN 5
#define PREVIEW_FOOTER_CELL_HEIGHT 27
#define UPDATE_LABEL_WIDTH 228
#define UPDATE_LABEL_WIDTH_IN_PREVIEW 194
#define LOVE_LABEL_WIDTH 178
#define LOVE_LABEL_WIDTH_IN_PREVIEW 144
#define LOVE_PLUS_ONE_LABEL_WIDTH 200
#define REPLY_LABEL_WIDTH 190
#define PILL_BUTTON_CELL_HEIGHT 40
#define CONTAINER_BACKGROUND_ORIGIN_X 7.5
#define CONTAINER_BACKGROUND_WIDTH 305
#define CONTAINER_IMAGE_VIEW_TAG 2819
#define TIMELINE_VIEW_TAG 2820
#define TIMELINE_ORIGIN_X 50
#define TIMESTAMP_LEFT_MARGIN 4
#define CELL_SEPARATOR_TAG 2349

- (NSString *)textForPost:(CPPost *)post
{
    if ((post.type == CPPostTypeUpdate || post.originalPostID) && post.author.userID != [CPUserDefaultsHandler currentUser].userID) {
        return [NSString stringWithFormat:@"%@: %@", post.author.firstName, post.entry];
    } else if (!post.originalPostID && post.type == CPPostTypeQuestion) {
        return [NSString stringWithFormat:@"Question from %@: %@", post.author.nickname, post.entry];
    } else if (!post.originalPostID && post.type == CPPostTypeCheckin) {
        if (post.author.userID != [CPUserDefaultsHandler currentUser].userID) {
            return post.entry;
        } else {
            // parse out the username and replace with 'You'
            return [post.entry stringByReplacingOccurrencesOfString:post.author.nickname withString:@"You"];
        }        
    } else {
        return post.entry;
    }
}

- (UIFont *)fontForPost:(CPPost *)post
{
    if (post.type != CPPostTypeLove || post.originalPostID) {
        return [UIFont systemFontOfSize:14];
    } else {
        return [UIFont boldSystemFontOfSize:14];
    }
}

- (CGFloat)widthForLabelForPost:(CPPost *)post isPostInPreview:(BOOL)isPostInPreview
{
    if (isPostInPreview) {
        if (post.type == CPPostTypeLove && !post.originalPostID) {
            return LOVE_LABEL_WIDTH_IN_PREVIEW;
        } else {
            return UPDATE_LABEL_WIDTH_IN_PREVIEW;
        }
    } else {
        if (post.type == CPPostTypeLove && !post.originalPostID) {
            return LOVE_LABEL_WIDTH;
        } else {
            return !post.originalPostID ? UPDATE_LABEL_WIDTH : REPLY_LABEL_WIDTH;
        }
    }
}

- (CGFloat)labelHeightWithText:(NSString *)text labelWidth:(CGFloat)labelWidth labelFont:(UIFont *)labelFont
{
    // limit to 3 lines of text in preview mode
    return [self labelHeightWithText:text
                          labelWidth:labelWidth
                           labelFont:labelFont
                           maxHeight:(self.selectedVenueFeed ? MAXFLOAT : labelFont.lineHeight * 3)];
}

- (CGFloat)labelHeightWithText:(NSString *)text labelWidth:(CGFloat)labelWidth labelFont:(UIFont *)labelFont maxHeight:(CGFloat)maxHeight
{
    return [text sizeWithFont:labelFont
            constrainedToSize:CGSizeMake(labelWidth, maxHeight)
                lineBreakMode:UILineBreakModeWordWrap].height;
    
}

- (CGFloat)cellHeightWithLabelHeight:(CGFloat)labelHeight cellPost:(CPPost *)cellPost isLastPostInPreview:(BOOL)isLastPostInPreview
{
    CGFloat cellHeight = labelHeight;
    CGFloat bottomMargin;
    CGFloat minCellHeight;
    
    // keep a 17 pt margin
    // but only if this isn't the last post in a preview
    if (self.selectedVenueFeed || !isLastPostInPreview) {
        // use the default bottom margin and top margin
        bottomMargin = LABEL_BOTTOM_MARGIN;
        
        // if this is a post in a selected venue feed that has replies then we need to drop the margin
        if (self.selectedVenueFeed && cellPost.replies.count) {
            bottomMargin -= 12;
        }
        
        minCellHeight = MIN_CELL_HEIGHT; 
    } else {
        // keep the right bottom margin for this last post
        bottomMargin = LAST_PREVIEW_POST_LABEL_BOTTOM_MARGIN;
        
        // this is the last cell in a preview so reduce the minCellHeight
        minCellHeight = LAST_PREVIEW_POST_MIN_CELL_HEIGHT;
    }
    
    // give the appropriate bottomMargin to this cell
    cellHeight += bottomMargin;
    
    // make sure labelHeight isn't smaller than our min cell height    
    return cellHeight > minCellHeight ? cellHeight : minCellHeight;
}

- (int)paddingForPendingPost
{
    if (self.pendingPost.type == CPPostTypeQuestion) {
        return !self.pendingPost.originalPostID ? 18 : 15;
    } else {
        return !self.pendingPost.originalPostID ? 15 : 12;
    }
}

- (UIImageView *)containerImageViewForPosition:(FeedBGContainerPosition)position containerHeight:(CGFloat)containerHeight
{
    NSString *filename;
    UIEdgeInsets insets;
    
    // switch-case to set variables dependent on the position this is for
    switch (position) {
        case FeedBGContainerPositionTop:
            filename = @"venue-feed-bg-container-top";
            insets = UIEdgeInsetsMake(6, 0, 0, 0);
            containerHeight = PREVIEW_HEADER_CELL_HEIGHT;
            break;
        case FeedBGContainerPositionMiddle:
            filename = @"venue-feed-bg-container-middle";
            insets = UIEdgeInsetsMake(0, 0, 0, 0);
            break;
        case FeedBGContainerPositionBottom:
            insets = UIEdgeInsetsMake(0, 0, 8, 0);
            filename = @"venue-feed-bg-container-bottom";
            break;
        default:
            break;
    }
    
    UIImage *containerImage = [[UIImage imageNamed:filename] resizableImageWithCapInsets:insets];
    
    // create a UIImageView with the image
    UIImageView *containerImageView = [[UIImageView alloc] initWithImage:containerImage];
    
    // change the frame of the imageView to leave spacing on the side
    CGRect containerIVFrame = containerImageView.frame;
    containerIVFrame.origin.x = CONTAINER_BACKGROUND_ORIGIN_X;
    containerIVFrame.size.width = CONTAINER_BACKGROUND_WIDTH;
    containerIVFrame.size.height = containerHeight;
    containerImageView.frame = containerIVFrame;
    
    if (position != FeedBGContainerPositionMiddle) {
        CGFloat timelineHeight = (position == FeedBGContainerPositionTop) ? 2 : (containerHeight - 4);
        
        UIView *timelineView = [[self class] timelineViewWithHeight:timelineHeight];
        
        // make adjustments to the timeLine autoresizing and frame
        timelineView.autoresizingMask = UIViewAutoresizingNone;
        
        CGRect timelineFrame = timelineView.frame;
        timelineFrame.origin.x = TIMELINE_ORIGIN_X - containerIVFrame.origin.x;
        
        if (position == FeedBGContainerPositionTop) {
            timelineFrame.origin.y = containerIVFrame.size.height - timelineHeight;
        }
        
        timelineView.frame = timelineFrame;
        
        // add the timeline to the containerImageView
        [containerImageView addSubview:timelineView];
    }
    
    // give the UIImageView a tag so we can check for its presence later
    containerImageView.tag = CONTAINER_IMAGE_VIEW_TAG;
    
    return containerImageView;
}

- (void)setupContainerBackgroundForCell:(UITableViewCell *)cell 
                     containerHeight:(CGFloat)containerHeight 
                       position:(FeedBGContainerPosition)position
{    
    UIView *containerView;
    
    // add the viewToAdd if it doesn't already exist on this cell
    if (!(containerView = [cell.contentView viewWithTag:CONTAINER_IMAGE_VIEW_TAG])) {
        containerView = [self containerImageViewForPosition:position containerHeight:containerHeight];
        
        // add that view to the cell's contentView
        [cell.contentView insertSubview:containerView atIndex:0];
        
    } else {
        if (position == FeedBGContainerPositionMiddle) {
            // adjust the view's height if required
            CGRect viewHeightFix = containerView.frame;
            viewHeightFix.size.height = containerHeight;
            containerView.frame = viewHeightFix;
        } else if (self.previewPostableFeedsOnly) {
            // make sure the timeline views are removed from the header and footer
            [containerView viewWithTag:TIMELINE_VIEW_TAG].hidden = YES;
        } else {
            // make sure the timeline views are shown in the header and footer
            [containerView viewWithTag:TIMELINE_VIEW_TAG].hidden = NO;
        }
        
    }
}

- (void)addSeperatorViewtoCell:(UITableViewCell *)cell isPostInPreview:(BOOL)isPostInPreview
{
    UIView *separatorView;
    
    if (!(separatorView = [cell.contentView viewWithTag:CELL_SEPARATOR_TAG])) {
        CGRect separatorViewFrame = CGRectMake(CONTAINER_BACKGROUND_ORIGIN_X + 2,
                                               cell.contentView.frame.size.height - 5,
                                               CONTAINER_BACKGROUND_WIDTH - 5,
                                               1);
        
        if (isPostInPreview) {
            separatorViewFrame.size.width = 5 + PREVIEW_POST_MAX_WIDTH - separatorViewFrame.origin.x;
        }
        
        UIView *separatorView = [[UIView alloc] initWithFrame:separatorViewFrame];
        separatorView.backgroundColor = [UIColor colorWithR:239 G:239 B:239 A:1];
        separatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;        
        separatorView.tag = CELL_SEPARATOR_TAG;
        
        // add the separatorView to the cell's contentView
        [cell.contentView addSubview:separatorView];
    } else {
        // make sure the separator is in the right spot
        CGRect separatorViewMove = separatorView.frame;
        separatorViewMove.origin.y = cell.contentView.frame.size.height - 5;
        separatorView.frame = separatorViewMove;
    }
}

#define REPLY_BUBBLE_ORIGIN_X 62
#define REPLY_BUBBLE_WIDTH 250
#define REPLY_BUBBLE_IMAGE_VIEW_TAG 2820
#define REPLY_BUBBLE_HEADER_HEIGHT 18
#define REPLY_BUBBLE_FOOTER_HEIGHT 15

- (UIImageView *)replyBubbleImageViewForPosition:(FeedBGContainerPosition)position containerHeight:(CGFloat)containerHeight
{
    NSString *filename;
    UIEdgeInsets insets;
    
    // switch-case to set variables dependent on the position this is for
    switch (position) {
        case FeedBGContainerPositionTop:
            filename = @"comment-bubble-top";
            insets = UIEdgeInsetsMake(11, 36, 0, 11);
            break;
        case FeedBGContainerPositionMiddle:
            filename = @"comment-bubble-middle";
            insets = UIEdgeInsetsMake(0, 3, 0, 3);
            break;
        case FeedBGContainerPositionBottom:
            insets = UIEdgeInsetsMake(0, 0, 8, 0);
            filename = @"comment-bubble-bottom";
            break;
        default:
            break;
    }
    
    UIImage *containerImage = [[UIImage imageNamed:filename] resizableImageWithCapInsets:insets];
    
    // create a UIImageView with the image
    UIImageView *containerImageView = [[UIImageView alloc] initWithImage:containerImage];
    
    // change the frame of the imageView to leave spacing on the side
    CGRect containerIVFrame = containerImageView.frame;
    containerIVFrame.origin.x = REPLY_BUBBLE_ORIGIN_X;
    containerIVFrame.size.width = REPLY_BUBBLE_WIDTH;
    containerIVFrame.size.height = containerHeight;
    containerImageView.frame = containerIVFrame;
    
    // give the UIImageView a tag so we can check for its presence later
    containerImageView.tag = CONTAINER_IMAGE_VIEW_TAG;
    
    return containerImageView;
}

- (void)setupReplyBubbleForCell:(UITableViewCell *)cell
                        containerHeight:(CGFloat)containerHeight
                               position:(FeedBGContainerPosition)position
{
    UIView *containerView;
    
    // add the viewToAdd if it doesn't already exist on this cell
    if (!(containerView = [cell.contentView viewWithTag:CONTAINER_IMAGE_VIEW_TAG])) {
        containerView = [self replyBubbleImageViewForPosition:position containerHeight:containerHeight];
        
        // add that view to the cell's contentView
        [cell.contentView insertSubview:containerView atIndex:0];
    } else {
        if (position == FeedBGContainerPositionMiddle) {
            // adjust the view's height if required
            CGRect viewHeightFix = containerView.frame;
            viewHeightFix.size.height = containerHeight;
            containerView.frame = viewHeightFix;
        }
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [CPUserActionCell cancelOpenSlideActionButtonsNotification:nil];
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight;
    
    if (!self.selectedVenueFeed) {
        if (indexPath.row == 0) {
            CPVenueFeed *sectionVenueFeed = [self venueFeedPreviewForIndex:indexPath.section];
            
            CGFloat postsTotalHeight = 0;
            NSInteger count = 0;
            for (CPPost *post in sectionVenueFeed.posts) {
                BOOL isLast = NO;
                if (++count >= 3 || count == [sectionVenueFeed.posts count]) {
                    isLast = YES;
                }
                
                CGFloat labelHeight = [self labelHeightWithText:[self textForPost:post]
                                                     labelWidth:[self widthForLabelForPost:post isPostInPreview:YES]
                                                      labelFont:[self fontForPost:post]];
                CGFloat cellHeight = [self cellHeightWithLabelHeight:labelHeight cellPost:post isLastPostInPreview:isLast];
                
                postsTotalHeight += cellHeight;
                
                if (isLast) {
                    break;
                }
            }
            
            return PREVIEW_HEADER_CELL_HEIGHT + PREVIEW_FOOTER_CELL_HEIGHT + postsTotalHeight;
        } else if (indexPath.row == (self.previewPostableFeedsOnly ? 1 : [self tableView:self.tableView numberOfRowsInSection:indexPath.section] - 1)) {
            return PREVIEW_FOOTER_CELL_HEIGHT;
        }
    }
    
    CPPost *cellPost;
    
    if (self.selectedVenueFeed) {
        // pull the post at this section
        cellPost = [self.selectedVenueFeed.posts objectAtIndex:indexPath.section];
        
        // if this is the comment / +1 box cell then our height is static
        if ((!cellPost.replies.count && indexPath.row == 1) || indexPath.row > cellPost.replies.count + 2) {
            return PILL_BUTTON_CELL_HEIGHT;
        } else if (indexPath.row > cellPost.replies.count + 1 || indexPath.row == 1) {
            return indexPath.row == 1 ? REPLY_BUBBLE_HEADER_HEIGHT : REPLY_BUBBLE_FOOTER_HEIGHT + 3;
        } else if (indexPath.row > 0) {
            // if the indexPath is not 0 and isn't the last this is a reply
            cellPost = [cellPost.replies objectAtIndex:indexPath.row - 2];
        }
        
        // check if we have a pendingPost and if this is it
        if (cellPost == self.pendingPost) {
            // this is an editable cell
            // for which we might have a changed height
            
            // check if we have a new cell height which is larger than our min height and grow to that size
            cellHeight = self.newEditableCellHeight > MIN_CELL_HEIGHT ? self.newEditableCellHeight : MIN_CELL_HEIGHT;
            
            return cellHeight;
        }
    } else {
        // grab post from venue feed preview
        NSArray *posts = [[self venueFeedPreviewForIndex:indexPath.section] posts];
        cellPost = [posts objectAtIndex:(indexPath.row - 1)];
    }
    
    // use helper methods to get label height and cell height
    CGFloat labelHeight = [self labelHeightWithText:[self textForPost:cellPost]
                                         labelWidth:[self widthForLabelForPost:cellPost isPostInPreview:NO]
                                          labelFont:[self fontForPost:cellPost]];
    
    cellHeight = [self cellHeightWithLabelHeight:labelHeight cellPost:cellPost isLastPostInPreview:NO];
    
    // return the calculated labelHeight
    return cellHeight;
}

#pragma mark - Table view data source


- (int)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.selectedVenueFeed) {
        // this is for a selectedVenueFeed, number of sections in tableView is number of posts
        return self.selectedVenueFeed.posts.count;
    } else {
        // this is for venue feed previews, either all or only postable
        return self.previewPostableFeedsOnly ? self.postableVenueFeeds.count : self.venueFeedPreviews.count;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.selectedVenueFeed) {
        // if this is for a single venue then the number of rows depends on the existence of replies
        // one for the post itself, one for comment / +1 footer, one for reply header and footer, and then one for each reply
        int replies = ((CPPost *)[self.selectedVenueFeed.posts objectAtIndex:section]).replies.count;
        int rows = 2;
        
        if (replies) {
            rows += replies + 2;
        }
        
        return rows;
    } else {
        return 1;
    }
}

- (FeedPreviewCell *)feedPreviewCellForSectionVenueFeed:(CPVenueFeed *)sectionVenueFeed tableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath
{
    CPVenue *currentVenue = [CPUserDefaultsHandler currentVenue];
    BOOL isCurrentVenue = sectionVenueFeed.venue.venueID == currentVenue.venueID;
    FeedPreviewCell *headerCell;
    
    if (self.previewPostableFeedsOnly) {
        static NSString *FeedPostablePreviewHeaderCellIdentifier = @"FeedPostablePreviewHeaderCell";
        headerCell = [tableView dequeueReusableCellWithIdentifier:FeedPostablePreviewHeaderCellIdentifier];
    } else {
        static NSString *FeedPreviewHeaderCellIdentifier = @"FeedPreviewHeaderCell";
        headerCell = [tableView dequeueReusableCellWithIdentifier:FeedPreviewHeaderCellIdentifier];
    }
    
    [self setupContainerBackgroundForCell:headerCell
                          containerHeight:PREVIEW_HEADER_CELL_HEIGHT 
                                 position:FeedBGContainerPositionTop];
    
    headerCell.delegate = self;
    headerCell.removeButton.hidden = isCurrentVenue;
    // give that label the venue name and change font to league gothic
    headerCell.venueNameLabel.text = sectionVenueFeed.venue.name;
    [CPUIHelper changeFontForLabel:headerCell.venueNameLabel toLeagueGothicOfSize:24];
    
    if (!self.previewPostableFeedsOnly) {
        [CPUIHelper changeFontForLabel:headerCell.relativeTimeLabel toLeagueGothicOfSize:24];
        
        // give the relative time string to the cell
        // if this venue has posts in the preview
        // otherwise leave it blank
        NSDate *firstPostDate;
        if (sectionVenueFeed.posts.count > 0) {
            
            //
            // the venue date needs to be localized for relativeTimeStringFromDateNow to work (see #18247).
            //
            if ((sectionVenueFeed.venue.utc) &&
                ([sectionVenueFeed.venue.utc length] > 0)) {
                firstPostDate = [CPUtils localizeDate:[[sectionVenueFeed.posts objectAtIndex:0] date]
                                        offsetFromUtc:[sectionVenueFeed.venue.utc intValue]];
            }
            else {
#if DEBUG
                NSLog(@"Warning: venue %@ is missing a utc (offset from UTC)", sectionVenueFeed.venue.name);
#endif
                // defaulting to the date of the post, the time displayed will be off by the offset of the venue!
                firstPostDate = [[sectionVenueFeed.posts objectAtIndex:0] date];
            }
        }
        
        headerCell.relativeTimeLabel.text = [CPUtils relativeTimeStringFromDateToNow:firstPostDate];
        
        if (headerCell.relativeTimeLabel.text) {
            // we need to stick the timestamp right beside the venue name
            CGSize timestampSize = [headerCell.relativeTimeLabel.text sizeWithFont:headerCell.relativeTimeLabel.font];
            CGSize venueNameSize = [headerCell.venueNameLabel.text sizeWithFont:headerCell.venueNameLabel.font];
            
            // stick the timestamp label to the venue name
            CGRect timestampShift = headerCell.relativeTimeLabel.frame;
            CGFloat removeButtonWidth = (headerCell.removeButton.hidden) ? 0 : 23;
            timestampShift.origin.x = (CONTAINER_BACKGROUND_WIDTH + CONTAINER_BACKGROUND_ORIGIN_X - removeButtonWidth) - timestampSize.width - 18;
            
            // the venueNameLabel will cut into the time stamp so shrink it
            CGRect venueNameShrink = headerCell.venueNameLabel.frame;
            
            if ((headerCell.venueNameLabel.frame.origin.x + venueNameSize.width) > timestampShift.origin.x) {
                venueNameShrink.size.width = timestampShift.origin.x - venueNameShrink.origin.x - TIMESTAMP_LEFT_MARGIN;
            } else {
                venueNameShrink.size.width = venueNameSize.width;
                timestampShift.origin.x = (venueNameShrink.origin.x + venueNameShrink.size.width + TIMESTAMP_LEFT_MARGIN);
            }
            
            headerCell.venueNameLabel.frame = venueNameShrink;
            headerCell.relativeTimeLabel.frame = timestampShift;                   
        }
    }
    
    NSInteger count = 0;
    for (CPPost *post in sectionVenueFeed.posts) {
        BOOL isLast = NO;
        if (++count >= 3 || count == [sectionVenueFeed.posts count]) {
            isLast = YES;
        }
        
        CGFloat labelHeight = [self labelHeightWithText:[self textForPost:post]
                                             labelWidth:[self widthForLabelForPost:post isPostInPreview:YES]
                                              labelFont:[self fontForPost:post]];
        CGFloat cellHeight = [self cellHeightWithLabelHeight:labelHeight cellPost:post isLastPostInPreview:isLast];
        
        [headerCell addPostCell:[self postCellForPost:post
                                            tableView:tableView
                                cellSeperatorRequired:!isLast
                                      isPostInPreview:YES
                                  isLastPostInPreview:isLast]
                     withHeight:cellHeight];
        
        if (isLast) {
            break;
        }
    }
    
    [headerCell setFeedPreviewFooterCell:[self feedPreviewFooterCell:tableView]
                              withHeight:PREVIEW_FOOTER_CELL_HEIGHT];
    
    return headerCell;
}

- (UITableViewCell *)feedPreviewFooterCell:(UITableView *)tableView
{
    static NSString *FeedPreviewFooterCellIdentifier = @"FeedPreviewFooterCell";
    UITableViewCell *feedPreviewFooterCell = [tableView dequeueReusableCellWithIdentifier:FeedPreviewFooterCellIdentifier];
    
    if (!feedPreviewFooterCell) {
        feedPreviewFooterCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:FeedPreviewFooterCellIdentifier];
        feedPreviewFooterCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // containerHeight needs to be the cellHeight minus the desired separation between the feed previews
    [self setupContainerBackgroundForCell:feedPreviewFooterCell
                          containerHeight:PREVIEW_FOOTER_CELL_HEIGHT - 9
                                 position:FeedBGContainerPositionBottom];
    
    return feedPreviewFooterCell;
}

- (NewPostCell *)newPostCellForPost:(CPPost *)post tableView:(UITableView *)tableView
{
    NewPostCell *newEntryCell;
    
    if (post.originalPostID) {
        static NSString *NewReplyCellIdentifier = @"NewPostReplyCell";
        newEntryCell = [tableView dequeueReusableCellWithIdentifier:NewReplyCellIdentifier];
    } else {
        static NSString *NewEntryCellIdentifier = @"NewPostCell";
        newEntryCell = [tableView dequeueReusableCellWithIdentifier:NewEntryCellIdentifier];
    }            
    
    // get the cursor to the right place
    // by padding it with leading spaces for whatever the leading text is
    
    NSString *leadingText;
    
    if (self.pendingPost.type == CPPostTypeQuestion) {
        leadingText = !self.pendingPost.originalPostID ? @"Question" : @"Answer";
    } else {
        leadingText = !self.pendingPost.originalPostID ? @"Update" : @"Reply";
    }
    
    // give the entry label the right text and color
    newEntryCell.entryLabel.textColor = [CPUIHelper CPTealColor];
    
    // if the entry was blank (new entry) we need to setup the leading spaces
    newEntryCell.entryLabel.text = [leadingText stringByAppendingString:@":"];
    
    
    // add the right number of leading spaces
    newEntryCell.growingTextView.text = self.pendingPost.entry;
    
    if (!newEntryCell.growingTextView.text.length) {
        int numberOfSpaces = [self paddingForPendingPost];
        for (int i = 0; i < numberOfSpaces; i++) {
            newEntryCell.growingTextView.text = [newEntryCell.growingTextView.text stringByAppendingString:@" "];
        }
    }
    
    newEntryCell.growingTextView.returnKeyType = UIReturnKeySend;
    
    // be the delegate of the HPGrowingTextView on this cell
    newEntryCell.growingTextView.delegate = self;
    
    // this is our pending entry cell
    self.pendingPostCell = newEntryCell;
    
    return newEntryCell;
}

- (PostUpdateCell *)postUpdateCellForPost:(CPPost *)post tableView:(UITableView *)tableView
{
    // this is an update cell
    // so check if it's this user's or somebody else's
    PostUpdateCell *updateCell;
    
    if (!post.originalPostID && post.author.userID == [CPUserDefaultsHandler currentUser].userID){
        static NSString *EntryCellIdentifier = @"MyPostUpdateCell";
        updateCell = [tableView dequeueReusableCellWithIdentifier:EntryCellIdentifier];
        
        if (self.selectedVenueFeed) {
            // create a singleton NSDateFormatter that we'll keep using
            static NSDateFormatter *logFormatter = nil;
            
            if (!logFormatter) {
                logFormatter = [[NSDateFormatter alloc] init];
                logFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
                logFormatter.AMSymbol = @"a";
                logFormatter.PMSymbol = @"p";
            }
            
            // setup the format for the time label
            logFormatter.dateFormat = @"h:mma";
            updateCell.timeLabel.text = [logFormatter stringFromDate:post.date];
            
            // setup the format for the date label
            logFormatter.dateFormat = @"MMM d";
            updateCell.dateLabel.text = [logFormatter stringFromDate:post.date];
        } else {
            updateCell.dateLabel.text = nil;
            updateCell.timeLabel.text = nil;
        }
    } else {
        // this is an update from another user
        static NSString *OtherUserEntryCellIdentifier = @"PostUpdateCell";
        updateCell = [tableView dequeueReusableCellWithIdentifier:OtherUserEntryCellIdentifier];
    }
    
    return updateCell;
}

- (PostBaseCell *)postCellForPost:(CPPost *)post tableView:(UITableView *)tableView cellSeperatorRequired:(BOOL)cellSeperatorRequired isPostInPreview:(BOOL)isPostInPreview isLastPostInPreview:(BOOL)isLastPostInPreview
{
    PostBaseCell *cell;
    
    // check if this is a pending entry cell
    if (self.pendingPost && post == self.pendingPost) {
        cell = [self newPostCellForPost:post tableView:tableView];
    } else {
        // check which type of cell we are dealing with
        if (post.originalPostID) {
            static NSString *PostReplyCellIdentifier = @"PostReplyCell";
            cell = [tableView dequeueReusableCellWithIdentifier:PostReplyCellIdentifier];
        } else if (post.type != CPPostTypeLove) {
            cell = [self postUpdateCellForPost:post tableView:tableView];
        } else {
            // this is a love cell
            static NSString *loveCellIdentifier = @"PostLoveCell";
            PostLoveCell *loveCell = [tableView dequeueReusableCellWithIdentifier:loveCellIdentifier];
            
            // setup the receiver's profile button
            [self loadProfileImageForButton:loveCell.receiverProfileButton photoURL:post.receiver.photoURL];
            
            loveCell.entryLabel.text = post.entry.description;
            
            // if this is a plus one we need to make the label wider
            // or reset it if it's not
            CGRect loveLabelFrame = loveCell.entryLabel.frame;
            loveLabelFrame.size.width = post.originalPostID > 0 ? LOVE_PLUS_ONE_LABEL_WIDTH : LOVE_LABEL_WIDTH;
            loveCell.entryLabel.frame = loveLabelFrame;
            
            // the cell to return is the loveCell
            cell = loveCell;
        }
        
        // the text for this entry is prepended with NICKNAME:
        cell.entryLabel.font = [self fontForPost:post];
        cell.entryLabel.text = [self textForPost:post];
        // make the frame of the label larger if required for a multi-line entry
        CGRect entryFrame = cell.entryLabel.frame;
        
        if (isPostInPreview) {
            entryFrame.size.width = [self widthForLabelForPost:post
                                               isPostInPreview:isPostInPreview];
        }
        
        entryFrame.size.height = [self labelHeightWithText:cell.entryLabel.text
                                                labelWidth:entryFrame.size.width
                                                 labelFont:cell.entryLabel.font];
        
        cell.entryLabel.frame = entryFrame;
        
        // fade out the text if we exceed the height requirements
        CGFloat fullHeight = [self labelHeightWithText:cell.entryLabel.text
                                            labelWidth:entryFrame.size.width
                                             labelFont:cell.entryLabel.font
                                             maxHeight:MAXFLOAT];
        [cell updateGradientAndSetVisible:(fullHeight > entryFrame.size.height)];
        
    }
    
    // setup the entry sender's profile button
    [self loadProfileImageForButton:cell.senderProfileButton photoURL:post.author.photoURL];
    
    if (self.selectedVenueFeed) {
        // remove the container background from this cell, if it exists
        // remove the separator view
        [[cell viewWithTag:CONTAINER_IMAGE_VIEW_TAG] removeFromSuperview];
        [[cell viewWithTag:CELL_SEPARATOR_TAG] removeFromSuperview];
        
        if (post.originalPostID) {
            [self setupReplyBubbleForCell:cell
                          containerHeight:[self cellHeightWithLabelHeight:cell.entryLabel.frame.size.height
                                                                 cellPost:post
                                                      isLastPostInPreview:isLastPostInPreview]
                                 position:FeedBGContainerPositionMiddle];
        }
    } else {
        [self setupContainerBackgroundForCell:cell
                              containerHeight:[self cellHeightWithLabelHeight:cell.entryLabel.frame.size.height
                                                                     cellPost:post
                                                          isLastPostInPreview:isLastPostInPreview]
                                     position:FeedBGContainerPositionMiddle];
        
        if (cellSeperatorRequired) {
            [self addSeperatorViewtoCell:cell isPostInPreview:isPostInPreview];
        } else {
            // remove the cell separator if it exists
            [[cell viewWithTag:CELL_SEPARATOR_TAG] removeFromSuperview];
        }
    }
    
    cell.activeColor = self.tableView.backgroundColor;
    cell.inactiveColor = self.tableView.backgroundColor;
    cell.user = post.author;
    cell.delegate = self;
    
    // return the cell
    cell.post = post;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{    
    CPPost *post;
    BOOL cellSeperatorRequired;

    if (!self.selectedVenueFeed) {
        CPVenueFeed *sectionVenueFeed = [self venueFeedPreviewForIndex:indexPath.section];
        
        // check if this is for a header 
        // or a footer for a venue feed preview
        if (indexPath.row == 0) {
            return [self feedPreviewCellForSectionVenueFeed:sectionVenueFeed tableView:tableView indexPath:indexPath];
        } else if (indexPath.row == [tableView numberOfRowsInSection:indexPath.section] - 1) {
            return [self feedPreviewFooterCell:tableView];
        } else {
            cellSeperatorRequired = indexPath.row != sectionVenueFeed.posts.count && indexPath.row != 3;
            // pull the right post from the feed preview for this venue
            post = [sectionVenueFeed.posts objectAtIndex:(indexPath.row - 1)];
        }
    } else {
        // pull the right post or reply from the selectedVenueFeed's posts
        post = [self.selectedVenueFeed.posts objectAtIndex:indexPath.section];
        
        // if this is supposed to be a reply then the post object should be a reply of the post we just grabbed
        if (indexPath.row > 0) {
            post = (indexPath.row < [self.tableView numberOfRowsInSection:indexPath.section] - 2 && indexPath.row > 1)
                    ? [post.replies objectAtIndex:(indexPath.row - 2)] : nil;
        }
    }
    
    if (post) {
        return [self postCellForPost:post
                           tableView:tableView
               cellSeperatorRequired:cellSeperatorRequired
                     isPostInPreview:NO
                 isLastPostInPreview:NO];
    } else {
        if (indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1) {
            // this is the comment / +1 cell for a post in selected venue feed
            CommentCell *commentCell = [self.tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
            CPPost *originalPost = [self.selectedVenueFeed.posts objectAtIndex:indexPath.section];
            commentCell.post = originalPost;
            commentCell.delegate = self;
            commentCell.venue = self.selectedVenueFeed.venue;
            
            // update the +1/comment pill widget to reflect the likeCount on the parent post
            [commentCell updatePillButtonAnimated:NO];
            
            return commentCell;
        } else {
            UITableViewCell *replyBubbleExtraCell;
            
            static NSString *ReplyBubbleHeaderIdentifier = @"ReplyBubbleHeader";
            static NSString *ReplyBubbleFooterIdentifier = @"ReplyBubbleFooter";
            
            // setup variables correctly for header or footer of bubble
            NSString *containerIdentifier = indexPath.row == 1 ? ReplyBubbleHeaderIdentifier : ReplyBubbleFooterIdentifier;
            FeedBGContainerPosition containerPosition = indexPath.row == 1 ? FeedBGContainerPositionTop : FeedBGContainerPositionBottom;
            CGFloat containerHeight = indexPath.row == 1 ? REPLY_BUBBLE_HEADER_HEIGHT : REPLY_BUBBLE_FOOTER_HEIGHT;
            
            // try and pull a cell for reuse
            replyBubbleExtraCell = [self.tableView dequeueReusableCellWithIdentifier:containerIdentifier];
            
            // otherwise we need to alloc-init it
            if (!replyBubbleExtraCell) {
                replyBubbleExtraCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:containerIdentifier];
                [self setupReplyBubbleForCell:replyBubbleExtraCell containerHeight:containerHeight position:containerPosition];
                replyBubbleExtraCell.selectionStyle = UITableViewCellSelectionStyleNone;
                [replyBubbleExtraCell addSubview:[FeedViewController timelineViewWithHeight:replyBubbleExtraCell.frame.size.height]];
            }
            
            // return the cell
            return replyBubbleExtraCell;
        }
    }
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        // first header in venue feed previews and selected feed view should have 9pt header
        return 9;
    } else {
        // no header required
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [[UIView alloc] init];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == [tableView numberOfSections] - 1) {
        // give the tableView a footer so that the bottom cells clear the button
        return [CPAppDelegate tabBarController].thinBar.actionButton.frame.size.width / 2;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{   
    // return an empty view
    return [[UIView alloc] init];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.selectedVenueFeed) {
        // the user has just tapped on a venue feed preview
        // so bring them to that feed
        
        [self transitionToVenueFeedForSection:indexPath.section];
    }
}

#pragma mark - VC Helper Methods
- (void)newFeedVenueAdded:(NSNotification *)notification
{
    // reload the venues for which we want feed previews
    [self reloadFeedPreviewVenues];
}

- (void)setupForPostEntry
{
    if (!self.fakeTextView) {
        // add a hidden UITextView so we can use it to become the first responder
        self.fakeTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
        self.fakeTextView.hidden = YES;
        self.fakeTextView.keyboardAppearance = UIKeyboardAppearanceAlert;
        self.fakeTextView.returnKeyType = UIReturnKeyDone;
        [self.view insertSubview:self.fakeTextView belowSubview:self.tableView];
    }
        
    if (!self.keyboardBackground) {
        // Add notifications for keyboard showing / hiding
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
        
        // create a CGRect for the base of our view
        // we're going to hide things there
        CGRect baseRect = CGRectMake(0, [CPAppDelegate window].bounds.size.height, self.view.frame.size.width, 0);
        
        // add a view so we can have a background behind the keyboard
        self.keyboardBackground = [[UIView alloc] initWithFrame:baseRect];
        self.keyboardBackground.backgroundColor = [UIColor colorWithR:51 G:51 B:51 A:1];
        
        // add the keyboardBackground to the view
        [[CPAppDelegate window] addSubview:self.keyboardBackground];
    } 
    
    // make sure the left bar button item is a back button
}

- (void)reloadFeedPreviewVenues
{    
    CPVenue *currentVenue = [CPUserDefaultsHandler currentVenue];
    // if it exists add the user's current venue as the first object in self.venues
    if (currentVenue) { 
        // create a CPVenueFeed object with the currentVenue as the venue
        CPVenueFeed *currentVenueFeed = [[CPVenueFeed alloc] init];
        currentVenueFeed.venue = currentVenue;

        NSUInteger venueIndex = [self.venueFeedPreviews indexOfObject:currentVenueFeed];
        if (venueIndex > 0) {
            if (venueIndex != NSNotFound) {
                currentVenueFeed = [self.venueFeedPreviews objectAtIndex:venueIndex];
            }
            // if the currentVenueFeed already exists in the array of venueFeedPreviews
            // then take it out so it can get added back at the beginning
            [self.venueFeedPreviews removeObject:currentVenueFeed];

            // add the current venue feed to the beginning of the array of venue feed previews
            [self.venueFeedPreviews insertObject:currentVenueFeed atIndex:0];
        }

    }

    if (![CPUserDefaultsHandler hasFeedVenues]) {
        // there is nothing saved in the feed venues setting
        [self findActiveFeeds];
    } else {
        [self showVenueFeeds];
    }
}

- (void)findActiveFeeds {
    [CPapi getNearestVenuesWithActiveFeeds:[CPUserDefaultsHandler currentUser].location
                                completion:
     ^(NSDictionary *json, NSError *error) {
         // give the user some reasonable default feeds
         if (!error) {
             // de-JSONify active venue list
             NSMutableArray *activeVenues = [NSMutableArray array];
             NSArray *venues = [[json objectForKey:@"payload"] valueForKey:@"venues"];
             for (NSDictionary *venueJSON in venues) {
                 CPVenue *venue = [[CPVenue alloc] initFromDictionary:venueJSON];
                 [activeVenues addObject:venue];
             }

             // sort the venues by most active
             [activeVenues sortUsingComparator:^NSComparisonResult(id a, id b) {
                 NSNumber *first = [NSNumber numberWithUnsignedInteger:[a postsCount]];
                 NSNumber *second = [NSNumber numberWithUnsignedInteger:[b postsCount]];
                 // compare the two post counts, flipping the order
                 return [second compare:first];
             }];

             // Add the top 3 most active feeds
             NSRange range = NSMakeRange(0, activeVenues.count >= AUTO_ACTIVE_FEED_COUNT ? AUTO_ACTIVE_FEED_COUNT : activeVenues.count);
             activeVenues = [[activeVenues subarrayWithRange:range] mutableCopy];
             
             for (CPVenue *venue in activeVenues) {
                 [CPUserDefaultsHandler addFeedVenue:venue];
             }
             
             // call toggleTableViewState to get a reload
             [self toggleTableViewState];
         } else {
             NSLog(@"Error retrieving default venues.");
         }
     }];
}
         
- (void)showVenueFeeds {
    CPVenue *currentVenue = [CPUserDefaultsHandler currentVenue];
    NSDictionary *storedFeedVenues = [CPUserDefaultsHandler feedVenues];
    for (NSString *venueIDKey in storedFeedVenues) {
        // grab the NSData representation of the venue and decode it
        NSData *venueData = [storedFeedVenues objectForKey:venueIDKey];
        CPVenue *decodedVenue = [NSKeyedUnarchiver unarchiveObjectWithData:venueData];
        
        // only add the venue if the user isn't checked in there
        if (decodedVenue.venueID != currentVenue.venueID) {
            // create a CPVenueFeed object with the decodedVenue as the venue
            CPVenueFeed *newVenueFeed = [[CPVenueFeed alloc] init];
            newVenueFeed.venue = decodedVenue;
            
            // add the new venue feed to the array of venue feed previews
            // but only if it's not already there
            if (![self.venueFeedPreviews containsObject:newVenueFeed]) {
                [self.venueFeedPreviews addObject:newVenueFeed];
            }
        }
    }    
}

- (void)showVenueFeedForVenue:(CPVenue *)venueToShow
{
    // enumerate through our venue feeds and find the one for this venue
    // it should be in here given that it was added by the NSNotification sent from CPUserDefaultsHandler
    for (CPVenueFeed *venueFeed in self.venueFeedPreviews) {
        if ([venueFeed.venue isEqual:venueToShow]) {
            self.selectedVenueFeed = venueFeed;
            break;
        }
    }
}

- (void)toggleTableViewState
{
    if (!self.selectedVenueFeed) {
        // this is for venue feed previews (either all feeds or only postable)
        if (self.previewPostableFeedsOnly) {
            // our title is the default
            self.navigationItem.title = @"Choose Feed";
        } else {
            // our title is the default
            self.navigationItem.title = @"Active Feeds";
        }
        
        // no pull to refresh in this table
        [self.tableView.pullToRefreshView stopAnimating];
        self.tableView.showsPullToRefresh = NO;
        
        // make sure we have the reload button in the top right
        [self addRefreshButtonToNavigationItem];
        
        // make sure the settings button is available in the top left
        self.navigationItem.leftBarButtonItem = nil;
        [CPUIHelper settingsButtonForNavigationItem:self.navigationItem];
        
        // get venue feed previews
        [self getVenueFeedOrFeedPreviews];
        
        // set the proper background color for the tableView
        self.tableView.backgroundColor = [UIColor colorWithR:242 G:242 B:242 A:1.0];
        self.tableView.backgroundView = nil;
        
        // don't show the scroll indicator in feed previews
        self.tableView.showsVerticalScrollIndicator = NO;
        
    } else {
        // this is for a selected venue feed
        
        // make sure that pull to refresh is now enabled for the tableview
        self.tableView.showsPullToRefresh = YES;
        
        // add a back button as the left navigation item
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Feeds" style:UIBarButtonItemStyleBordered target:self action:@selector(backFromSelectedFeed:)];
        // our new title is the name of the venue
        self.navigationItem.title = self.selectedVenueFeed.venue.name;
        
        if (!self.pendingPost) {
            // trigger a refresh of the pullToRefreshView which will refresh our data
            [self.tableView.pullToRefreshView triggerRefresh];
        }
        
        // set the proper background color for the tableView
        self.tableView.backgroundColor = [UIColor colorWithR:246 G:247 B:245 A:1.0];
        
        // this is a selected venue feed so show the timeline as the background view
        
        // setup a background view
        // and add the timeline to the backgroundView
        UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 1)];
        [backgroundView addSubview:[[self class] timelineViewWithHeight:1]];
        backgroundView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        self.tableView.backgroundView = backgroundView;
        
        // show the scroll inidicator in a selected feed
        self.tableView.showsVerticalScrollIndicator = YES;
    }
    
    if (self.pendingPost) {
        // restore state for pending posts when returning from lock screen, etc.
        int section = [self.selectedVenueFeed indexOfPostWithID:self.pendingPost.originalPostID];
        int row = [[self.selectedVenueFeed.posts objectAtIndex:section] replies].count;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];

        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
        [self cancelButtonForRightNavigationItem];
        self.tableView.showsPullToRefresh = NO;
    } else {
        [self.tableView reloadData];
    }
}

- (void)loadProfileImageForButton:(UIButton *)button photoURL:(NSURL *)photoURL
{   
    __block UIButton *profileButton = button;
    
    // call setImageWithURLRequest and use the success block to set the downloaded image as the background image of the button
    // on failure do nothing since the background image on the button has been reset to the default profile image in prepare for reuse
    
    // we use the button's read-only imageView just to be able to peform the request using AFNetworking's caching
    [button.imageView setImageWithURLRequest:[NSURLRequest requestWithURL:photoURL]
                            placeholderImage:[CPUIHelper defaultProfileImage]
                                     success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        // give the downloaded image to the button
        [profileButton setImage:image forState:UIControlStateNormal];
    } failure:nil];
    
    // be the target of the button
    [button addTarget:self action:@selector(pushToUserProfileFromButton:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)addRefreshButtonToNavigationItem
{
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(getVenueFeedOrFeedPreviews)];
}

- (void)toggleLoadingState:(BOOL)loading
{
    if (loading) {
        // show a HUD unless this is the pull to refresh table
        if (!self.tableView.showsPullToRefresh) {
            [SVProgressHUD showWithStatus:@"Loading..."];
        }

        // our current state is log reload
        self.currentState = FeedVCStateReloadingFeed;
    } else {
        // show a HUD or the pullToRefreshView
        if (self.tableView.showsPullToRefresh) {
            // dismiss the pullToRefreshView in the tableView       
            [self.tableView.pullToRefreshView stopAnimating];
        } else {
            // dismiss the progressHUD
            [SVProgressHUD dismiss];
        }
        
        // our current state is now the default
        self.currentState = FeedVCStateDefault;
    } 
}

- (void)getVenueFeedOrFeedPreviews
{
    [self toggleLoadingState:YES];
    
    self.postPlussingUserIds = [NSMutableDictionary new];
    
    if (self.selectedVenueFeed) {  
        // make the request with CPapi to get the feed for this selected venue
        [CPapi getPostsForVenueFeed:self.selectedVenueFeed withCompletion:^(NSDictionary *json, NSError *error) {
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {

                    NSDictionary *jsonDict = [json objectForKey:@"payload"];
                    [self.selectedVenueFeed addPostsFromArray:[jsonDict objectForKey:@"feeds"]];
                    int timestamp = [[jsonDict objectForKey:@"timestamp"] integerValue];

                    // last ID property for venue feed is now the ID of the first post in the selectedVenueFeed posts array
                    if (self.selectedVenueFeed.posts.count) {
                        self.selectedVenueFeed.lastID = [[self.selectedVenueFeed.posts objectAtIndex:0] postID];
                    }
                    
                    [self toggleLoadingState:NO];
                    // reload the tableView
                    [self.tableView reloadData];
                    
                    // check if we were loaded because the user immediately wants to add a new entry
                    if (self.newPostAfterLoad) {
                        // if that's the case then pull let the user add a new entry
                        [self newPost:nil];
                        // reset the newpostAfterLoad property so it doesn't fire again
                        self.newPostAfterLoad = NO;
                    } else {
                        // go to the top of the tableView
                        [self scrollTableViewToTopAnimated:YES];
                        
                        // load the replies to the posts for this venue feed
                        [CPapi getPostRepliesForVenueFeed:self.selectedVenueFeed withCompletion:^(NSDictionary *json, NSError *error) {
                            if (!error) {
                                if (![[json objectForKey:@"error"] boolValue]) {
                                    [self.selectedVenueFeed addRepliesFromDictionary:[json objectForKey:@"payload"]];
                                    
                                    // tell the tableView to reload so it shows the replies
                                    [self.tableView reloadData];
                                }
                            }
                            self.selectedVenueFeed.updateTimestamp = timestamp;
                        }];
                    }
                } else {
                    [self toggleLoadingState:NO];
                    [SVProgressHUD showErrorWithStatus:[json objectForKey:@"message"]
                                              duration:kDefaultDismissDelay];
                }
            }
        }];
    } else if (self.venueFeedPreviews.count) {
        // create an array of the venue IDs for which we want feed previews
        NSMutableArray *venueIDs = [NSMutableArray arrayWithCapacity:self.venueFeedPreviews.count];
        for (CPVenueFeed *venueFeed in self.venueFeedPreviews) {
            [venueIDs addObject:[NSNumber numberWithInt:venueFeed.venue.venueID]];
        }
        
        // ask the API for the feed previews
        [CPapi getFeedPreviewsForVenueIDs:venueIDs withCompletion:^(NSDictionary *json, NSError *error) {
            if (!error) {
                NSDictionary *feedPreviews = [json objectForKey:@"payload"];
                
                // enumerate through the feeds returned
                for (NSString *venueIDString in feedPreviews) {
                    [self addPostsToFeedPreview:[feedPreviews objectForKey:venueIDString] venueIDString:venueIDString];
                }
                
                // tell the tableView to reload
                [self.tableView reloadData];
            }
            
            // we're done loading
            [self toggleLoadingState:NO];
        }];
    } else {
        [self toggleLoadingState:NO];
    }
}
         
- (void)addPostsToFeedPreview:(NSArray *)postArray venueIDString:(NSString *)venueIDString
{
    // TODO: make sure this isn't a slowdown
    // if so we'll want a faster way to pull a feed from the array (an ordered dictionary)
    
    // enumerate through the feeds in the venueFeedPreviews array
    // once we find the right one then tell it to add the posts that have come back
    for (CPVenueFeed *feed in self.venueFeedPreviews) {
        if (feed.venue.venueID == [venueIDString intValue]) {
            [feed addPostsFromArray:postArray];
        }
    }
}

#define SECONDS_IN_HOUR 3600

- (void)sendNewPost
{
    // let's grab the cell that this entry is for
    self.pendingPost.entry = [self.pendingPostCell.growingTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // send a log entry as long as it's not blank
    // and we're not in the process of sending a log entry
    if (![self.pendingPost.entry isEqualToString:@""] && ![self.navigationItem.rightBarButtonItem.customView isKindOfClass:[UIActivityIndicatorView class]]) {
        
        // create a spinner to use in the top right of the navigation controller
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        [spinner startAnimating];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
        
        [CPapi newPost:self.pendingPost atVenue:self.selectedVenueFeed.venue completion:^(NSDictionary *json, NSError *error) {
            if (!error) {
                if (![[json objectForKey:@"error"] boolValue]) {
                                        
                    self.currentState = FeedVCStateSentNewPost;
                    
                    // the ID of the new post is returned as the payload
                    self.pendingPost.postID = [[json objectForKey:@"payload"] integerValue];
                    
                    // drop the self.pendingPost to the pending entry now that it's sent
                    CPPost *sentEntry = self.pendingPost;
                    self.pendingPost = nil;
                    
                    // no error, log sent successfully. let's add the completed log object to the array and reload the table
                    //
                    if ((self.selectedVenueFeed.venue.utc) &&
                        ([self.selectedVenueFeed.venue.utc length] > 0)) {
                        int offset = [self.selectedVenueFeed.venue.utc intValue];
                        sentEntry.date = [[NSDate alloc] initWithTimeIntervalSinceNow:(offset*SECONDS_IN_HOUR)];
                    }
                    else {
                        sentEntry.date = [NSDate date];
                    }
                    [self.tableView reloadData];
                } else {
                    
                }
            }
        }];
    }
}

- (void)scrollTableViewToTopAnimated:(BOOL)animated
{
    // scroll to the top of the tableView
    [self.tableView setContentOffset:CGPointMake(0, 0) animated:animated];
}

- (void)showOnlyPostableFeeds
{
    // we only need to download the array of postable feeds if we don't already have it
    
    // check if we are already shown (otherwise we're about to be transitioned to by method in CPTabBarController)
    // if we are then check if
    BOOL forceList = (self.tabBarController.selectedIndex != 0);
    
    // let the TVC know that we want to only show the postable feeds
    self.previewPostableFeedsOnly = YES;
    
    // anytime the user says they want to post a feed for a venue they are not checked into
    // we call this API function to return array of venue IDs we can post to
    
    // assume they are all in our local list of feeds
    [self toggleLoadingState:YES];
    
    [CPapi getPostableFeedVenueIDs:^(NSDictionary *json, NSError *error){
        if (!error) {
            if (![[json objectForKey:@"error"] boolValue]) {
                NSArray *venueIDs = [json objectForKey:@"payload"];
                self.postableVenueFeeds = [NSMutableArray arrayWithCapacity:venueIDs.count];
                
                for (CPVenueFeed *venueFeed in self.venueFeedPreviews) {
                    if ([venueIDs containsObject:[NSString stringWithFormat:@"%d", venueFeed.venue.venueID]]) {
                        // add this venueFeed to the array of postableVenueFeeds
                        [self.postableVenueFeeds addObject:venueFeed];
                    }
                }
                
                [self toggleLoadingState:NO];
                
                if (!forceList && self.selectedVenueFeed && [self.postableVenueFeeds containsObject:self.selectedVenueFeed]) {
                    // no need to change anything, we're looking at a feed that is postable
                    // post to it
                    [self newPost:nil];
                } else {
                    // make sure the selectedVenueFeed is nil
                    // that will also toggle the tableView state
                    self.selectedVenueFeed = nil;
                    
                    // add a cancel button in the top right so the user can go back to all feeds
                    [self cancelButtonForRightNavigationItem];
                }
            }
        }
    }];
}

- (CPVenueFeed *)venueFeedPreviewForIndex:(NSInteger)index
{
    return self.previewPostableFeedsOnly ? [self.postableVenueFeeds objectAtIndex:index] : [self.venueFeedPreviews objectAtIndex:index];
}

- (void)transitionToVenueFeedForSection:(NSInteger)section
{
    // make sure that the HUD for loading venue feed previews isn't sticking around
    [SVProgressHUD dismiss];
    
    self.selectedVenueFeed = [self venueFeedPreviewForIndex:section];
    
    if (self.previewPostableFeedsOnly) {
        // once the TVC has loaded the feed we want to add a new update
        self.newPostAfterLoad = YES;
    }
}

- (void)cancelButtonForRightNavigationItem
{
    // add a cancel button to our nav bar so the user can drop out of creation
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelPost:)];
}

#pragma mark - IBActions
- (void)newPost:(NSIndexPath *)replyToIndexPath
{
    // let's make sure we're setup for post entry
    [self setupForPostEntry];
    
    if (self.currentState == FeedVCStateReloadingFeed) {
        // if the log is currently reloading
        // or the view isn't yet visible
        // then don't try to add a newpost right away
        // set our property that will pull up the keyboard after the load is complete
        self.newPostAfterLoad = YES;
        
        // don't continue execution of this method, get out of here
        return;
    }
    
    // only try to add a new log if we aren't in the middle of adding one now
    // or if we aren't reloading the user's logs
    if (!self.pendingPost) {
        // switch the state of the thinBar's button
        
        // we need to add a new cell to the table with a textView that the user can edit
        // first create a new CPpost object
        self.pendingPost = [[CPPost alloc] init];
        
        // the author for this log message is the current user
        self.pendingPost.author = [CPUserDefaultsHandler currentUser];
        
        if (replyToIndexPath) {
            CPPost *originalPost = [self.selectedVenueFeed.posts objectAtIndex:replyToIndexPath.section];
            
            // this log's original post ID is the id of the that post
            self.pendingPost.originalPostID = originalPost.postID;
            
            // this log's type is the same of the original post
            self.pendingPost.type = originalPost.type;
            
            // this is a reply to an existing post to add it to that posts' array of replies
            [originalPost.replies addObject:self.pendingPost];
        } else {
            self.pendingPost.type = self.postType;
            [self.selectedVenueFeed.posts insertObject:self.pendingPost atIndex:0];
        }
        
        if (self.pendingPost.type == CPPostTypeQuestion) {
            [CPAppDelegate tabBarController].thinBar.actionButtonState = CPThinTabBarActionButtonStateQuestion;
        } else {
            [CPAppDelegate tabBarController].thinBar.actionButtonState = CPThinTabBarActionButtonStateUpdate;
        }
        
        // we need the keyboard to know that we're asking for this change
        self.currentState = FeedVCStateAddingOrRemovingPendingPost;
        
        [self cancelButtonForRightNavigationItem];
        
        // tell the tableView to stop scrolling, it'll be completed by the keyboard being displayed
        self.tableView.contentOffset = self.tableView.contentOffset;
        
        // only become firstResponder if this view is currently on screen
        // otherwise that gets taken care once the view appears
        if (self.tabBarController.selectedIndex != 0) {
            // let's make sure the selected index of the CPTabBarController is the logbook's
            // before allowing update
            self.tabBarController.selectedIndex = 0;
        } else {
            // show the keyboard so the user can start input
            // by using our fakeTextView to slide up the keyboard
            [self.fakeTextView becomeFirstResponder];
        }
    }
}

- (IBAction)cancelPost:(id)sender {
    if (!self.selectedVenueFeed) {
        // the user is looking at the list postable feeds and wants to switch to the list of all feeds
        self.previewPostableFeedsOnly = NO;
        [self toggleTableViewState];
    } else if (self.currentState != FeedVCStateAddingOrRemovingPendingPost) {
        // confirm the currentState is correct so that we
        // don't allow a double tap on the cancel button to crash the app
        
        // user is cancelling new post
        
        // remove the pending post from the right array (depending on wether its an original post or a reply)
        if (!self.pendingPost.originalPostID) {
            [self.selectedVenueFeed.posts removeObject:self.pendingPost];
        } else {
            CPPost *originalPost = [self.selectedVenueFeed.posts objectAtIndex:[self.selectedVenueFeed indexOfPostWithID:self.pendingPost.originalPostID]];
            [originalPost.replies removeObject:self.pendingPost];
        }
        
        // we need the keyboard to know that we're asking for this change
        self.currentState = FeedVCStateAddingOrRemovingPendingPost;
        
        // switch first responder to our fake textView and then resign it so we can drop the keyboard
        [self.fakeTextView becomeFirstResponder];
        [self.fakeTextView resignFirstResponder];
        
        // scroll to the top of the table view
        [self scrollTableViewToTopAnimated:YES];
    }
}

- (IBAction)pushToUserProfileFromButton:(UIButton *)button
{
    if (self.selectedVenueFeed) {
        // grab the post that is associated to this button
        // first we need the indexPath of this cell
        NSIndexPath *selectedPath = [self.tableView indexPathForRowAtPoint:[[button superview] convertPoint:button.center toView:self.tableView]];
        
        CPPost *userEntry = [self.selectedVenueFeed.posts objectAtIndex:selectedPath.section];
        
        if (selectedPath.row > 0) {
            userEntry = [userEntry.replies objectAtIndex:(selectedPath.row - 2)];
        }
        
        // if this button's origin is left of the timeline then it's the log's author
        // otherwise it's the log's receiver
        User *selectedUser = (userEntry.originalPostID || button.frame.origin.x < TIMELINE_ORIGIN_X)
                             ? userEntry.author : userEntry.receiver;
        
        if (selectedUser.userID) {
            // push the user profile
            UserProfileViewController *userProfileViewController = (UserProfileViewController *)[[UIStoryboard storyboardWithName:@"UserProfileStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"UserProfileViewController"];
            userProfileViewController.title = selectedUser.nickname;
            [self.navigationController pushViewController:userProfileViewController animated:YES];
            userProfileViewController.user = selectedUser;
        }
    } else {
        // we need to show the venue feed for this venue
        // the button's tag is the section for this feed
        [self transitionToVenueFeedForSection:button.tag];
    }
}

- (IBAction)backFromSelectedFeed:(id)sender
{
    // if the user is adding a post then cancel the pending post
    if (self.pendingPost) {
        [self cancelPost:nil];
    }
    
    // we're coming back from a selected feed
    // we should no longer just be showing postable feeds
    self.previewPostableFeedsOnly = NO;
    
    // nil out the selectedVenueFeed
    self.selectedVenueFeed = nil;
}

# pragma mark - Keyboard hide/show notification

- (void)keyboardWillShow:(NSNotification *)notification{
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:YES];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    [self fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:notification beingShown:NO];
}

- (void)fixChatBoxAndTableViewDuringKeyboardMovementFromNotification:(NSNotification *)notification beingShown:(BOOL)beingShown
{    
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // call our helper method to slide the UI elements
    [self slideUIElementsBasedOnKeyboardHeight:keyboardRect.size.height 
                             animationDuration:[[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue] 
                                    beingShown:beingShown];
}

- (void)slideUIElementsBasedOnKeyboardHeight:(CGFloat)keyboardHeight animationDuration:(CGFloat)animationDuration beingShown:(BOOL)beingShown
{
    // NOTE: it's pretty odd to be moving the UITabBar up and down and using it in our view
    // it's convenient though because it gives us the background and the log button
    
    keyboardHeight = beingShown ? keyboardHeight : -keyboardHeight;
    
    // don't move anything if the keyboard isn't being moved because of us
    if (self.currentState != FeedVCStateDefault) {
        
        CPThinTabBar *thinBar = [CPAppDelegate tabBarController].thinBar;
        
        // new CGRect for the UITabBar
        CGRect newTabBarFrame = thinBar.frame;
        newTabBarFrame.origin.y -= keyboardHeight;
        
        // setup a new CGRect for the tableView
        CGRect newTableViewFrame = self.tableView.frame;
        newTableViewFrame.size.height -= keyboardHeight;
        
        // new CGRect for keyboardBackground
        CGRect newBackgroundFrame = self.keyboardBackground.frame;
        newBackgroundFrame.origin.y -= keyboardHeight;
        newBackgroundFrame.size.height += keyboardHeight;
    
        // declare section and replyIndex here so we can use it later if applicable
        int section;
        int replyIndex;
        
        // only try and update the tableView if we've asked for this change by adding or removing an entry
        if (self.currentState == FeedVCStateAddingOrRemovingPendingPost) { 
            
            if (!beingShown) {
                // give the tableView its new frame ASAP so the animation of deleting the cell is right
                self.tableView.frame = newTableViewFrame;
            }
            
            [self.tableView beginUpdates];
        
            // check if this is a reply or an original post
            // and add/delete a row/section accordingly 
            if (!self.pendingPost.originalPostID) {
                NSIndexSet *postIndexSet = [NSIndexSet indexSetWithIndex:0];
                
                if (beingShown) {
                    [self.tableView insertSections:postIndexSet withRowAnimation:UITableViewRowAnimationTop];
                } else {
                    [self.tableView deleteSections:postIndexSet withRowAnimation:UITableViewRowAnimationTop];
                }
            } else {
                // get the index of the original post in the tableView by using CPVenueFeed's indexOfPostWithID method
                section = [self.selectedVenueFeed indexOfPostWithID:self.pendingPost.originalPostID];
                
                replyIndex = ((CPPost *)[self.selectedVenueFeed.posts objectAtIndex:section]).replies.count;
                
                // if the keyboard is being dropped then the row we need to drop is one higher then the count of replies
                replyIndex += beingShown ? 0 : 1;
                
                NSIndexPath *postIndexPath = [NSIndexPath indexPathForRow:(replyIndex + 1) inSection:section];
                NSMutableArray *indexPathArray = [NSMutableArray arrayWithObject:postIndexPath];
                
                // if this is/was the only reply for this post we need to add/delete more than just that cell
                if (replyIndex == 1) {
                    [indexPathArray addObject:[NSIndexPath indexPathForRow:1 inSection:section]];
                    [indexPathArray addObject:[NSIndexPath indexPathForRow:(replyIndex + 2) inSection:section]];
                }
                
                if (beingShown) {
                    [self.tableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
                } else {
                    [self.tableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
                }
            }
            
            // if not keyboard is dropping then nil out self.pendingPost
            if (!beingShown) {
                self.pendingPost = nil;
            }
            [self.tableView endUpdates];
        }
            
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:(UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState)
                         animations:^{
                             if (self.currentState == FeedVCStateAddingOrRemovingPendingPost ||
                                 self.currentState == FeedVCStateSentNewPost) {
                                 // give the tabBar its new frame
                                 thinBar.frame = newTabBarFrame;
                                 
                                 // toggle the alpha of the right side buttons and green line
                                 [thinBar toggleRightSide:!beingShown];
                                 
                                 // change the frame of the table view if we haven't already done so
                                 if ((!beingShown && self.currentState != FeedVCStateAddingOrRemovingPendingPost) ||
                                     beingShown) {
                                     // animate change in tableView's frame
                                     self.tableView.frame = newTableViewFrame;
                                 }
                                 
                                 self.tableView.showsPullToRefresh = !beingShown;
                                 
                                 if (beingShown) {
                                     if (!self.pendingPost.originalPostID) {
                                         // this is not a reply
                                         // get the tableView to scroll to the top while the keyboard is appearing
                                         [self scrollTableViewToTopAnimated:NO];
                                     } else {
                                         // this is a reply
                                         // scroll to the post being replied to
                                         NSIndexPath *replyToIndexPath = [NSIndexPath indexPathForRow:replyIndex inSection:section];
                                         [self.tableView scrollToRowAtIndexPath:replyToIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                                     }
                                     
                                     
                                     // swtich the thinBar's action button state to the right type
                                     if (CPPostTypeQuestion == self.postType) {
                                         [CPAppDelegate tabBarController].thinBar.actionButtonState = CPThinTabBarActionButtonStateQuestion;
                                     } else {
                                         [CPAppDelegate tabBarController].thinBar.actionButtonState = CPThinTabBarActionButtonStateUpdate;
                                     }
                                 } else {
                                     // switch the thinBar's action button state back to the plus button
                                     [CPAppDelegate tabBarController].thinBar.actionButtonState = CPThinTabBarActionButtonStatePlus;
                                     
                                     
                                 }
                             }
                             
                             // give the keyboard background its new frame
                             self.keyboardBackground.frame = newBackgroundFrame;                         
                         }
                         completion:^(BOOL finished){
                             if (beingShown) {
                                 // grab the new cell and make its growingTextView the first responder
                                 if (self.pendingPost) {
                                     [self.pendingPostCell.growingTextView becomeFirstResponder];
                                 }
                             } else {                                     
                                 // remove the cancel button
                                 self.navigationItem.rightBarButtonItem = nil;
                             }
                        
                             // reset the LogVCState
                             self.currentState = FeedVCStateDefault;
                         }];
    }
}

#pragma mark - HPGrowingTextViewDelegate
- (BOOL)growingTextView:(HPGrowingTextView *)growingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (range.location < [self paddingForPendingPost]) {
        return NO;
    } else {
        if ([text isEqualToString:@"\n"]) {
            // when the user clicks return it's the done button 
            // so send the update
            
            if (!self.pendingPost.originalPostID && self.pendingPost.type == CPPostTypeQuestion) {
                
                [CPapi getCurrentCheckInsCountAtVenue:self.selectedVenueFeed.venue 
                                       withCompletion:^(NSDictionary *json, NSError *error) {
                                           BOOL respError = [[json objectForKey:@"error"] boolValue];
                                           
                                           if (!error && !respError) {
                                               
                                               int count = [[json objectForKey:@"payload"] intValue];
                                               NSString *message;
                                               
                                               //user +1 person
                                               if (count == 2) {
                                                   message = @"It will be pushed to 1 person checked in to this location.";
                                               } else if (count > 2) {
                                                   message = [NSString stringWithFormat: @"It will be pushed to %d people checked in to this location.", count - 1];
                                               } else {
                                                   message = @"You are the only person here right now.";
                                               }
                                               
                                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Post a Question"
                                                                                               message:[NSString stringWithFormat:@"Are you sure you want to ask this question? %@", message]
                                                                                              delegate:self
                                                                                     cancelButtonTitle:@"No" 
                                                                                     otherButtonTitles:@"Yes", nil];
                                               [alert show];
                                               
                                           }
                                           
                                       }];
                
            } else {
                [self sendNewPost];   
            }
            return NO;
        } else {
            //Limit max length of the feed
            int strLen = [[growingTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length];
            int addLength = [text length] -  range.length;
            
            if (strLen + addLength > kMaxFeedLength) {
                return NO;
            } else {
                return YES;
            }
        }
    }
}

- (void)growingTextViewDidChangeSelection:(HPGrowingTextView *)growingTextView
{
    int limit = [self paddingForPendingPost];
    
    if (growingTextView.selectedRange.location < limit) {
        // make sure the end point was at least 16/18
        // if that's the case then allow the selection from 15/17 to the original end point
        int end = growingTextView.selectedRange.location + growingTextView.selectedRange.length;
        
        growingTextView.selectedRange = NSMakeRange(limit, end > limit ? end - limit : 0);
    }
}

- (void)growingTextView:(HPGrowingTextView *)growingTextView willChangeHeight:(float)height
{
    // get the difference in height
    float diff = (growingTextView.frame.size.height - height);
    
    if (diff != 0) {
        // grab the contentView of the cell
        UIView *cellContentView = [growingTextView superview];
        
        // set the newEditableCellHeight property so we can grab it when the tableView asks for the cell height
        CGFloat newHeight = cellContentView.frame.size.height - diff;
        self.newEditableCellHeight = newHeight;
        
        // call beginUpdates and endUpdates to get the tableView to change the height of the first cell
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
        
        // we need to make sure the speech bubble for this cell also fixes its height
        if (self.pendingPost.originalPostID) {
            [self setupReplyBubbleForCell:self.pendingPostCell containerHeight:newHeight position:FeedBGContainerPositionMiddle];
        }
    }
}

- (void)growingTextViewDidChange:(HPGrowingTextView *)growingTextView
{
    self.pendingPost.entry = growingTextView.text;
}

# pragma mark - CPUserActionCellDelegate

- (void)cell:(CPUserActionCell*)cell didSelectSendLoveToUser:(User*)user 
{
    [CPUserAction cell:cell sendLoveFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectSendMessageToUser:(User*)user 
{
    [CPUserAction cell:cell sendMessageFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectExchangeContactsWithUser:(User*)user
{
    [CPUserAction cell:cell exchangeContactsFromViewController:self];
}

- (void)cell:(CPUserActionCell*)cell didSelectRowWithUser:(User*)user 
{
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex 
{
    // Exchange contacts if accepted
    if ([actionSheet title] == kRequestToAddToMyContactsActionSheetTitle) {
        if (buttonIndex != [actionSheet cancelButtonIndex]) {
            [CPapi sendContactRequestToUserId:actionSheet.tag];
        }
    }
}

#pragma mark - FeedPreviewHeaderCellDelegate

- (void)removeButtonPressed:(FeedPreviewCell *)cell
{
    if ( ! self.selectedVenueFeed && ! self.previewPostableFeedsOnly) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        NSUInteger venueFeedIndex = indexPath.section;
        CPVenueFeed *venueFeed = [self.venueFeedPreviews objectAtIndex:venueFeedIndex];
        
        [self.tableView beginUpdates];
        
        [self.venueFeedPreviews removeObjectAtIndex:venueFeedIndex];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:venueFeedIndex]
                      withRowAnimation:UITableViewRowAnimationFade];
        
        [CPUserDefaultsHandler removeFeedVenueWithID:venueFeed.venue.venueID];
        
        [self.tableView endUpdates];
    }
}

#pragma mark - UITapGestureRecognizer Target
- (IBAction)pillButtonPressed:(UIButton *)pillButton
{
    // the user has held down the entry label for the required amount of time
    // let's pop open the reply bubble
    
    // this is done by calling newPost with the index path of the post being replied to
    NSIndexPath *tappedIndexPath = [self.tableView indexPathForRowAtPoint:[[pillButton superview] convertPoint:pillButton.center toView:self.tableView]];
    [self newPost:tappedIndexPath];
}
    
#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self sendNewPost]; 
    }
}

#pragma mark - Class methods
+ (UIView *)timelineViewWithHeight:(CGFloat)height
{
    // alloc-init the timeline view
    UIView *timeLine = [[UIView alloc] initWithFrame:CGRectMake(TIMELINE_ORIGIN_X, 0, 2, height)];
    
    // give it the right color
    timeLine.backgroundColor = [UIColor colorWithR:234 G:234 B:234 A:1];
    
    // allow it to autoresize with the view
    timeLine.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    
    // give it a tag so we can verify presence later
    timeLine.tag = TIMELINE_VIEW_TAG;
    
    return timeLine;
}

- (WEPopoverContainerViewProperties *)popoverContainerViewProperties {
    // layout and graphics properties for the popover
    WEPopoverContainerViewProperties *props = [WEPopoverContainerViewProperties new];
    NSString *bgImageName = nil;
    CGFloat bgMargin = 0.0;
    CGFloat bgCapSize = 0.0;
    CGFloat contentMargin = 4.0;
    
    bgImageName = @"pill-popover-background.png";
    
    // These constants are determined by the popoverBg.png image file and are image dependent
    bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13
    bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
    
    props.leftBgMargin = bgMargin;
    props.rightBgMargin = bgMargin;
    props.topBgMargin = bgMargin;
    props.bottomBgMargin = bgMargin;
    props.leftBgCapSize = bgCapSize;
    props.topBgCapSize = bgCapSize;
    props.bgImageName = bgImageName;
    props.leftContentMargin = contentMargin;
    props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
    props.topContentMargin = contentMargin;
    props.bottomContentMargin = contentMargin;
    
    props.arrowMargin = 4.0;
    
    props.upArrowImageName = @"popover-arrow-top.png";
    props.downArrowImageName = @"popover-arrow-bottom.png";
    props.leftArrowImageName = @"popover-arrow-left.png";
    props.rightArrowImageName = @"popover-arrow-right.png";
    return props;
}

- (void)dismissPopover
{
    // dismiss popover and reset state
    [self.wePopoverController dismissPopoverAnimated:YES];
    self.wePopoverController = nil;
    self.pillPopoverViewController = nil;
}
- (void)showPillPopoverFromCell:(CommentCell *)cell
{
    // present the popover from the specified cell.. dismiss if this was a second touch
    if (!self.wePopoverController) {
        UIButton *button = cell.pillButton;
		
        // grab a UserProfileViewController from the UserStoryboard
        self.pillPopoverViewController = (PillPopoverViewController *)[[UIStoryboard storyboardWithName:@"MainStoryboard_iPhone" bundle:nil] instantiateViewControllerWithIdentifier:@"PillPopoverViewController"];
        self.pillPopoverViewController.post = cell.post;
        self.pillPopoverViewController.indexPath = [self.tableView indexPathForCell:cell];
        self.pillPopoverViewController.delegate = self;
        self.wePopoverController = [[WEPopoverController alloc] initWithContentViewController:self.pillPopoverViewController];
        self.wePopoverController.popoverContentSize = CGSizeMake(172, 81);
        self.wePopoverController.delegate = self;
        [self.wePopoverController setContainerViewProperties:[self popoverContainerViewProperties]];
        CGRect rect = CGRectOffset([self.view convertRect:button.frame fromView:button.superview], -10, 0);
        [self.wePopoverController presentPopoverFromRect:rect
                                                  inView:self.view
                                permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight|UIPopoverArrowDirectionUp|UIPopoverArrowDirectionDown
                                                animated:YES];
	} else {
        [self dismissPopover];
	}
}

#pragma mark - WEPopoverControllerDelegate implementation

- (void)popoverControllerDidDismissPopover:(WEPopoverController *)thePopoverController {
    //Safe to release the popover here
    self.wePopoverController = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(WEPopoverController *)thePopoverController {
    //The popover is automatically dismissed if you click outside it, unless you return NO here
    return YES;
}

#pragma mark - PillPopoverDelegate implementation
- (void) pillPopover:(PillPopoverViewController *)pillPopoverViewController commentPressedForIndexPath:(NSIndexPath*)indexPath
{
    // dismiss popover and show the comment cell
    [self dismissPopover];
    [self newPost:indexPath];
}
- (void) pillPopover:(PillPopoverViewController *)pillPopoverViewController plusOnePressedForIndexPath:(NSIndexPath*)indexPath
{
    CommentCell *cell = (CommentCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell updatePillButtonAnimated:YES];
    [self dismissPopover];
}


@end
