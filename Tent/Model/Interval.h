//
//  Interval.h
//  Tent
//
//  Created by Jeremy on 8/4/14.
//  Copyright (c) 2014 Jeremy. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Interval : NSObject

@property (nonatomic) NSMutableArray *availablePersons;
@property (nonatomic) NSMutableArray *assignedPersons;
@property (nonatomic) NSDate *startDate;
@property (nonatomic) NSDate *endDate;
@property (nonatomic) NSString *timeString;
@property (nonatomic) NSString *dateTimeString;

@property (nonatomic) NSUInteger section;

-(instancetype)initWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate section:(NSUInteger) section;
@end
