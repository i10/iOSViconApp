//
//  ViconBody.h
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 11/30/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconObject.h"

@interface ViconBody : ViconObject {
	float		xRot;
	float		yRot;
	float		zRot;
	
	NSInteger	xrChannel;
	NSInteger	yrChannel;
	NSInteger	zrChannel;
}

@property (assign)	float		xRot;
@property (assign)	float		yRot;
@property (assign)	float		zRot;

@property (assign)	NSInteger	xrChannel;
@property (assign)	NSInteger	yrChannel;
@property (assign)	NSInteger	zrChannel;

@end
