//
//  ViconObject.h
//  SimpleViconGLClient
//
//  Created by Malte Weiß on 12/11/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

@interface ViconObject : NSObject {
	NSString	*name;
	NSString	*subjectName;
	BOOL		tracked;
	
	float		xPos;
	float		yPos;
	float		zPos;
	
	NSInteger	xChannel;
	NSInteger	yChannel;
	NSInteger	zChannel;
    
    float          xScreen, yScreen;    // Position of object on screen
}

@property (copy)	NSString*	name;
@property (copy)	NSString*	subjectName;
@property (assign)	BOOL		tracked;

@property (assign)	float		xPos;
@property (assign)	float		yPos;
@property (assign)	float		zPos;

@property (assign)  NSInteger	xChannel;
@property (assign)  NSInteger	yChannel;
@property (assign)  NSInteger	zChannel;

@property (assign)  float       xScreen;
@property (assign)  float       yScreen;

-(id)initWithEntityName:(NSString *)entityName;
-(void)updateDataFromChannelArray:(NSArray *)channelArray;



@end
