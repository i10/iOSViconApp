//
//  ViconMarker.m
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 11/30/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconMarker.h"


@implementation ViconMarker

@synthesize occlusion;
@synthesize occChannel;

-(void)updateDataFromChannelArray:(NSArray *)channelArray;
{
	self.xPos		= [channelArray[xChannel] floatValue];
	self.yPos		= [channelArray[yChannel] floatValue];
	self.zPos		= [channelArray[zChannel] floatValue];
	self.occlusion	= [channelArray[occChannel] floatValue];
}

@end
