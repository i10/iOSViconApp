//
//  ViconMarker.h
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 11/30/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconObject.h"

@interface ViconMarker : ViconObject {
	float		occlusion;
	NSInteger	occChannel;
}

@property (assign)	float		occlusion;
@property (assign) NSInteger	occChannel;

@end
