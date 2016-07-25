//
//  ViconServerConnection.h
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 12/1/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import <CoreFoundation/CoreFoundation.h>
#import "TrackingList.h"

@interface ViconServerConnection : NSObject

@property (strong, readonly) TrackingList *trackingList;
@property (nonatomic, readonly) BOOL connected;
@property (nonatomic, readonly) BOOL newDataReceived;


// public

-(void)connectToServer:(NSString *)address onPort:(int)port;
-(void)disconnect;



/*
 The behaviour should be something like that:
 create a new thread
	open the connection
	read the info packet and prepare the dictionary
	create a runLoop
	set the connection socket as a runloop source
	register whatever callbacks are needed to process the incoming data
	start the runloop (inside a while loop that checks for termination)
 
 in the callback
	enter data in a thread-safe way into the tracking list (all the data is stored in properties - property accessors are already thread-safe)
 
 */

@end
