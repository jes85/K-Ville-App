//
//  IntervalTableViewCell.m
//  Tent
//
//  Created by Jeremy on 8/2/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import "IntervalTableViewCell.h"

@implementation IntervalTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    //TODO: not exactly sure why this works. try to figure out a better way of having background colors permanently change on selection
    //[super setSelected:selected animated:animated];

    // Configure the view for the selected state
}




@end
