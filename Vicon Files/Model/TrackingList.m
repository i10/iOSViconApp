//
//  TrackingList.m
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 11/30/07.
//  Modified by Kashyap Todi on 05/02/13.

//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "TrackingList.h"



@implementation TrackingList

@synthesize trackingList;
@synthesize currentFrame;
@synthesize fpsSent;
@synthesize fpsReal;
@synthesize timeChannel;
@synthesize frozen;
@synthesize invalid;

- (id) init
{
	self = [super init];
	if (self != nil) {
		trackingList = [[NSArray alloc] init];
		invalid = NO;		
		frozen = FALSE;
	}
	
	return self;
}






#pragma mark -

-(void)updateDataFromChannelArray:(NSArray *)channelArray;
{
	// Reject data if frozen mode is activated
	if(frozen)
		return;
	
	// first, update the frame number from the time channel
	self.currentFrame = [channelArray objectAtIndex:self.timeChannel];
	
	// Update frame rate
	UnsignedWide currentTime;
//	Microseconds(&currentTime);
	
	if(startFrame == -1) startFrame = [self.currentFrame doubleValue];
	
	UInt32 diffTime = currentTime.lo - startTime.lo; // TODO: watch out for overflow into the high word!
	if(diffTime > 1000000)	// Every second
	{
//		Microseconds(&startTime);
		
		self.fpsReal = [NSNumber numberWithDouble:(([self.currentFrame doubleValue] - startFrame) / (diffTime / 1000000.0))];
		
		startTime = currentTime;
		startFrame = [self.currentFrame doubleValue];
	}
	
	// then ask each object in the trackingList to update itself
	for(id entity in self.trackingList)
	{
		[entity updateDataFromChannelArray:channelArray];
	}
	
}



- (IBAction)freeze:(id)sender;
{
	frozen = 1;
}



@end
