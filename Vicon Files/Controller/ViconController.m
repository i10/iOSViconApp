//
//  ViconController.m
//
//  Created by Kashyap Todi on 4/1/13.
//  Copyright (c) 2013 Media Computing Group - RWTH Aachen University. All rights reserved.
//
//

#import "ViconController.h"
#import "ViconServerConnection.h"

@interface ViconController()
@property (strong, nonatomic, readwrite) NSString *status;
@property (readwrite, nonatomic) BOOL enableConnection;
@property (strong, nonatomic) ViconServerConnection	*serverConnection;
@property (strong, nonatomic) NSString *ipAddressString;
@property (readwrite, nonatomic) BOOL connected;
@property (readwrite, nonatomic) BOOL newFrameReceived;
@property (readwrite, strong, nonatomic) NSArray *trackingList;
@end

@implementation ViconController


- (NSString *) ipAddressString
{
    if (!_ipAddressString)
        _ipAddressString = @"192.168.10.1"; //Hard-coded IP address for Vicon Server.
    
    return _ipAddressString;
}

#pragma mark -
#pragma mark Vicon Stuff

- (ViconServerConnection *) serverConnection
{
    if(!_serverConnection)
    {
        _serverConnection = [[ViconServerConnection alloc] init];
        [self.serverConnection addObserver:self forKeyPath:@"connected" options:NSKeyValueObservingOptionNew context:nil];
        
        [self.serverConnection addObserver:self forKeyPath:@"newDataReceived" options:NSKeyValueObservingOptionNew context:nil];
        self.connected = NO;
    }
    return _serverConnection;
}

//Toggle between "Connect" and "Disconnect", depending on current state.
- (void) connectOrDisconnectVicon
{
    if(self.serverConnection.connected)
	{
		// disconnect
		[self.serverConnection disconnect]; // kills the thread and toggles connection clean-up
		
		// change status label to 'disconnect'
		self.status = @"Disconnecting...";
	}
	else
	{
		// connect
		[self.serverConnection connectToServer:self.ipAddressString onPort:800];
		
		// change status label to 'disconnect'
		self.status = @"Connecting...";
	}
    
    self.enableConnection = NO;
}



//Observe changes in ViconServerConnection.

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    // Observe change in connection status.
    
    if ([object isEqual:self.serverConnection] && [keyPath isEqual:@"connected"])
	{
		if ([change[NSKeyValueChangeNewKey] boolValue] == YES)
		{
			// we just have been connected
			// change button label to 'disconnect'
			self.enableConnection = YES;
            self.connected = YES;
            self.status = @"Connected";
		}
        
		else
		{
			// we just have been disconnected
			// change button label to 'disconnect'
			self.enableConnection = YES;
            self.connected = NO;
            self.status = @"Disconnected";
		}
    }
    
    //Observe change in data in trackingList. ServerConnection uses a boolean "newDataReceived" to allow for KVO of the trackingList array.
    //TODO: Automatically observe change in the array "trackingList", and eliminate the BOOL "newDataReceived".
    
    if ([object isEqual:self.serverConnection] && [keyPath isEqual:@"newDataReceived"])
    {
        //Keep a local copy of the trackingList array.
        self.trackingList = [self.serverConnection.trackingList.trackingList copy];
        
        //Notify other classes (like ViewController), using KVO, that a new frame has been received.
        //TODO: Similary eliminate the need for this BOOL "newFrameReceived".
        self.newFrameReceived = YES;
    }
}

@end
