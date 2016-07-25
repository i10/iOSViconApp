//
//  ViconBody.m
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 11/30/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconBody.h"


@implementation ViconBody

@synthesize xRot;
@synthesize yRot;
@synthesize zRot;

@synthesize xrChannel;
@synthesize yrChannel;
@synthesize zrChannel;

-(void)updateDataFromChannelArray:(NSArray *)channelArray;
{
	self.xPos = [channelArray[xChannel] floatValue];
	self.yPos = [channelArray[yChannel] floatValue];
	self.zPos = [channelArray[zChannel] floatValue];
	self.xRot = [channelArray[xrChannel] floatValue];
	self.yRot = [channelArray[yrChannel] floatValue];
	self.zRot = [channelArray[zrChannel] floatValue];
}

@end
