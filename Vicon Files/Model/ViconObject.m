//
//  ViconObject.m
//  SimpleViconGLClient
//
//  Created by Malte Weiß on 12/11/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconObject.h"


@implementation ViconObject

@synthesize name;
@synthesize subjectName;
@synthesize tracked;

@synthesize xPos;
@synthesize yPos;
@synthesize zPos;

@synthesize xChannel;
@synthesize yChannel;
@synthesize zChannel;

@synthesize xScreen;
@synthesize yScreen;

- (id) initWithEntityName:(NSString *)entityName;
{
	self = [super init];
	if (self != nil) {
		NSArray *dividedString = [entityName componentsSeparatedByString:@":"];
		NSString *markerName = [dividedString lastObject];
		NSString *subject = @"";
		if ([dividedString count] > 1)
			subject = [dividedString objectAtIndex:0];
		
		self.subjectName = subject;
		self.name = markerName;
		self.tracked = YES;
	}
	return self;
}

-(void)updateDataFromChannelArray:(NSArray *)channelArray;
{
}



@end
