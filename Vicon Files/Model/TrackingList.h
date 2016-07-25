//
//  TrackingList.h
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 11/30/07.
//  Modified by Kashyap Todi on 05/02/13.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconMarker.h"
#import "ViconBody.h"


@interface TrackingList : NSObject {
    NSArray						*trackingList;
	NSNumber					*currentFrame;
	NSNumber					*fpsSent;
	NSNumber					*fpsReal;
	NSInteger					timeChannel;
	BOOL						frozen;
	
	UnsignedWide 				startTime;		// For computing framerate
	double						startFrame;
	
	BOOL						invalid;
	
	
    
}

@property (strong)		NSArray						*trackingList;
@property (copy)		NSNumber					*currentFrame;
@property (copy)		NSNumber					*fpsSent;
@property (copy)		NSNumber					*fpsReal;
@property (assign)		NSInteger					timeChannel;
@property (assign)		BOOL						frozen;
@property (assign)		BOOL						invalid;

/** the maximum number of csv records allowed. If the tracking list aquires more
 * records it will discard the old ones and start a new list. 
 */
- (id)init;
- (void)updateDataFromChannelArray:(NSArray *)channelArray;


- (IBAction)freeze:(id)sender;

// delegate methods for the TableView




@end

// This is the data source for the NSTableView