//
//  ViconServerConnection.m
//  SimpleViconGLClient
//
//  Created by Thorsten Karrer on 12/1/07.
//  Copyright 2007 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViconServerConnection.h"
#import <sys/socket.h>
#import <arpa/inet.h>
#pragma mark -
#pragma mark Global Definitions

enum EType		
{
	ERequest, 
	EReply
};

enum EPacket	
{
	EClose, 
	EInfo, 
	EData, 
	EStreamOn, 
	EStreamOff
};

@interface ViconServerConnection()
{
    NSString		*serverAddress;
	int				serverPort;
	
	NSMutableArray	*channelNames;
    
	CFReadStreamRef		readStream;
    CFWriteStreamRef	writeStream;
}

@property (nonatomic) CFReadStreamRef   readStream;
@property (nonatomic) CFWriteStreamRef  writeStream;
@property (strong, readwrite) TrackingList *trackingList;
@property (nonatomic) BOOL	shouldTerminate;
@property (nonatomic, readwrite) BOOL connected;
@property (nonatomic, readwrite) BOOL newDataReceived;


@end

@implementation ViconServerConnection
@synthesize readStream;
@synthesize writeStream;
@synthesize connected;

// public

- (id) init
{
	self = [super init];
	if (self) {
		channelNames = [[NSMutableArray alloc] init];
        _trackingList = [[TrackingList alloc] init];

	}
	return self;
}



-(void)connectToServer:(NSString *)address onPort:(int)port;
{
	if (self.connected)
		[self disconnect];
	
	serverAddress = [address copy];
	serverPort = port;
	
	self.shouldTerminate = NO;
	[NSThread detachNewThreadSelector:@selector(threadEntry:) toTarget:self withObject:nil];
}

-(void)disconnect;
{
	// tell the thread to stop
	NSLog(@"askind thread to die");
	self.shouldTerminate = YES;
}

// private

-(void)threadEntry:(id)param;
{
	@autoreleasepool {
	
		NSLog(@"thread alive");
    // Do thread work here
		
		// open the connection
		if (![self openConnection])
			goto bail;
		NSLog(@"connection open");
		
		// build up the lookup dictionary
		if (![self getInfoPacket])
			goto bail;
		NSLog(@"got info packet");
		
		/*
		CFStreamClientContext myContext = {0, self, NULL, NULL, NULL};
		
		CFOptionFlags registeredEvents = kCFStreamEventHasBytesAvailable |	kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered;
		if (CFReadStreamSetClient(readStream, registeredEvents, myReadStreamCallback, &myContext))
			CFReadStreamScheduleWithRunLoop(readStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		
		registeredEvents = kCFStreamEventCanAcceptBytes | kCFStreamEventErrorOccurred | kCFStreamEventEndEncountered;
		if (CFWriteStreamSetClient(writeStream, registeredEvents, myWriteStreamCallback, &myContext))
			CFWriteStreamScheduleWithRunLoop(writeStream, CFRunLoopGetCurrent(), kCFRunLoopCommonModes);
		*/
		
		// turn on streaming mode
		CFStreamStatus rStatus = CFReadStreamGetStatus(readStream);
		CFStreamStatus wStatus = CFWriteStreamGetStatus(writeStream);
		if (((rStatus == kCFStreamStatusError) || (wStatus == kCFStreamStatusError)) ||
			((rStatus == kCFStreamStatusClosed) || (wStatus == kCFStreamStatusClosed)) ||
			((rStatus == kCFStreamStatusAtEnd) || (wStatus == kCFStreamStatusAtEnd)))
		{
			NSLog(@"Connection terminated!");
		}
		
		self.connected = YES;
		
		while (!CFWriteStreamCanAcceptBytes(writeStream))
		{
			NSLog(@"cannot write");
			sleep(1);
		}
		
		UInt8 buffer[4096];		// buffer.  4K should be enough.
		CFIndex sent, rcvd, length;
		NSLog(@"send streaming request...");
		// we can send a request
		UInt8 * pBuff;
		pBuff = buffer;
		* ((int *) pBuff) = EStreamOn;
		pBuff += sizeof(int);
		* ((int *) pBuff) = ERequest;
		pBuff += sizeof(int);
		length = pBuff - buffer; // pointer arithmetics - beware of 64 bit! TODO 
		sent = rcvd = 0;
		while (sent < length)
		{
			CFIndex bytesSent = CFWriteStreamWrite(writeStream, buffer, length - sent);
			if (bytesSent <= 0)
			{
				NSLog(@"Error while writing request...");
				break;
			}
			sent += bytesSent;
		}
		NSLog(@"streaming request sent");
		
		
		// start the while loop
		while(!self.shouldTerminate)
		{
						
			rStatus = CFReadStreamGetStatus(readStream);
			wStatus = CFWriteStreamGetStatus(writeStream);
			if (((rStatus == kCFStreamStatusError) || (wStatus == kCFStreamStatusError)) ||
				((rStatus == kCFStreamStatusClosed) || (wStatus == kCFStreamStatusClosed)) ||
				((rStatus == kCFStreamStatusAtEnd) || (wStatus == kCFStreamStatusAtEnd)))
			{
				NSLog(@"Connection terminated!");
				break;
			}
			
			//NSLog(@"trying to receive data packet...");
			int kind;
			int type;
			int size;
			
			while (!CFReadStreamHasBytesAvailable(readStream))
			{
				//NSLog(@"waiting for incoming data...");
				//sleep(1);
			}
			
			if (![self recieveLong:&kind])
				NSLog(@"Error receiving packet kind..."); //TODO error handling
			if (![self recieveLong:&type])
				NSLog(@"Error receiving packet type..."); //TODO error handling
			if (kind != EData)
				NSLog(@"Error receiving: bad packet kind..."); //TODO error handling
			if (type != EReply)
				NSLog(@"Error receiving: bad packet type..."); //TODO error handling
			if (![self recieveLong:&size])
				NSLog(@"Error receiving packet size..."); //TODO error handling
			//if (size != [self.trackingList.trackingList count] + 1) // DOES NOT WORK BECAUSE OF UNKNOWN CODES
			//	NSLog(@"Error receiving: wrong packet size..."); //TODO error handling
			// now get the data
			//NSLog(@"packet seems ok - getting the data...");
			NSMutableArray *tempArray = [[NSMutableArray alloc] init];
			int i;
			double data;
			for (i = 0; i < size; ++i)
			{
				[self recieveDouble:&data];
				[tempArray addObject:@(data)];
				//sleep(0.1);
				//NSLog(@"receiving channel %d of %d -- data is %.2f", i+1, size, data);
			}
			[self.trackingList updateDataFromChannelArray:tempArray];
            
            //We now notify the ViconController (via KVO) that new data has been received.
            //TODO: Apply KVO directly to the "trackingList" array, and eliminate the BOOL "newDataReceived".
            self.newDataReceived = YES;
            
            
        }
		
		// turn off streaming mode
		rStatus = CFReadStreamGetStatus(readStream);
		wStatus = CFWriteStreamGetStatus(writeStream);
		if (((rStatus == kCFStreamStatusError) || (wStatus == kCFStreamStatusError)) ||
			((rStatus == kCFStreamStatusClosed) || (wStatus == kCFStreamStatusClosed)) ||
			((rStatus == kCFStreamStatusAtEnd) || (wStatus == kCFStreamStatusAtEnd)))
		{
			NSLog(@"Connection terminated!");
		}
		
		
		while (!CFWriteStreamCanAcceptBytes(writeStream))
		{
			NSLog(@"cannot write");
			sleep(1);
		}
		NSLog(@"send streaming off request...");  ///####################
		// we can send a request
		pBuff = buffer;
		* (( int *) pBuff) = EStreamOff;
		pBuff += sizeof( int);
		* (( int *) pBuff) = ERequest;
		pBuff += sizeof( int);
		length = pBuff - buffer; // pointer arithmetics - beware of 64 bit! TODO 
		sent = rcvd = 0;
		while (sent < length)
		{
			CFIndex bytesSent = CFWriteStreamWrite(self.writeStream, buffer, length - sent);
			if (bytesSent <= 0)
			{
				NSLog(@"Error while writing request...");
				break;
			}
			sent += bytesSent;
		}
		NSLog(@"streaming off request sent");
		
bail:
		// close connection if still open
		if (readStream)
		{
			CFReadStreamClose(readStream);
			CFRelease(readStream);
		}
		if (writeStream)
		{
			CFWriteStreamClose(writeStream);
			CFRelease(writeStream);
		}
		
		self.connected = NO;
		self.trackingList.invalid = YES;
	
		
		NSLog(@"thread dead");
    }
}

-(BOOL)waitForConnectionOnWriteStream;
{
	// Since in this test app we have nothing better to do, we just poll to check whether
    // the connection has succeeded.  In a real app, the better approach would be to return
    // to the RunLoop to service events, and watch for the kCFStreamEventCanAcceptBytes event.
    int i;
    for (i = 0; i < 15; i++) {
        if (CFWriteStreamCanAcceptBytes(writeStream))
            return YES;
        if (i == 1)
            NSLog(@"Waiting for connection...");
        sleep(1);
    }
	NSLog(@"...timeout!");
    return NO;
}

-(BOOL)openConnection;
{
	const char* host = [serverAddress UTF8String];
	UInt16 port;
	
	port = serverPort;
	
	NSLog(@"Connecting to server %s at port %d", host, port);
	
	// Check for a dotted-quad address, if so skip any host lookups
    in_addr_t addr = inet_addr(host);
	
    if (addr != INADDR_NONE) {
        // Create the streams from numerical host
        struct sockaddr_in sin;
        memset(&sin, 0, sizeof(sin));
		
        sin.sin_len= sizeof(sin);
        sin.sin_family = AF_INET;
        sin.sin_addr.s_addr = addr;
        sin.sin_port = htons(port);
		
        CFDataRef addressData = CFDataCreate(NULL, (UInt8 *)&sin, sizeof(sin));
        CFSocketSignature sig = { PF_INET, SOCK_STREAM, IPPROTO_TCP, addressData };
		// Create the streams.
		CFStreamCreatePairWithPeerSocketSignature(kCFAllocatorDefault, &sig, &readStream, &writeStream);
        CFRelease(addressData); // TODO not sure if that can be released here
    }
    else
	{
        // Create the streams from ascii host name
        CFStringRef hostStr = CFStringCreateWithCStringNoCopy(kCFAllocatorDefault, host, kCFStringEncodingUTF8, kCFAllocatorNull);
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, hostStr, port, &readStream, &writeStream);		
    }
	
	// Inform the streams to kill the socket when it is done with it.
    // This effects the write stream too since the pair shares the
    // one socket.
    CFReadStreamSetProperty(readStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
	
	if (CFReadStreamOpen(readStream) && CFWriteStreamOpen(writeStream) && [self waitForConnectionOnWriteStream])
		return YES; //streams are open and write stream accepts bytes to be written
	
	// something went wrong... clean up
	//if (readStream) CFRelease(readStream);
	//if (writeStream) CFRelease(writeStream);
	
	return NO;
}

-(BOOL)getInfoPacket;
{
	UInt8 buffer[4096];		// buffer.  4K should be enough.
	
	BOOL done = NO;
	
	while (!done)
	{
		CFStreamStatus rStatus = CFReadStreamGetStatus(readStream);
		CFStreamStatus wStatus = CFWriteStreamGetStatus(writeStream);
		
		CFIndex sent, rcvd, length;
		
		// Continue pumping along while waiting to open
		if ((rStatus == kCFStreamStatusOpening) || (wStatus == kCFStreamStatusOpening))
			continue;
		
		if (((rStatus == kCFStreamStatusError) || (wStatus == kCFStreamStatusError)) ||
			((rStatus == kCFStreamStatusClosed) || (wStatus == kCFStreamStatusClosed)) ||
			((rStatus == kCFStreamStatusAtEnd) || (wStatus == kCFStreamStatusAtEnd)))
		{
			NSLog(@"Connection terminated!");
			break;
		}
		
		UInt8 * pBuff;
		pBuff = buffer;
		* (( int *) pBuff) = EInfo;
		pBuff += sizeof( int);
		* (( int *) pBuff) = ERequest;
		pBuff += sizeof( int);
		length = pBuff - buffer; // pointer arithmetics - beware of 64 bit! TODO 
		
		// Start off with nothing
		sent = rcvd = 0;
		
		NSLog(@"Requesting info packet...");
		
		// Keep trying to send the data
		while (sent < length) {

			// Try to send
			CFIndex bytesSent = CFWriteStreamWrite(writeStream, buffer, length - sent);
			
			// Check to see if an error occurred
			if (bytesSent <= 0)
			{
				NSLog(@"Error while writing request...");
				break;
			}
			
			sent += bytesSent;
		}
		
		NSLog(@"Trying to receive info packet...");
		
		// Get Packet header
		 int kind;
		 int type;
		 int size;
		
		if(![self recieveLong: &kind]) {
			NSLog(@"Error while reading packet kind");
			break;
		}
		
		if(![self recieveLong: &type]) {
			NSLog(@"Error while reading packet type");
			break;
		}
		
		if(type != EReply || kind != EInfo) {
			NSLog(@"Received bad packet");
			break;
		}
		
		if(![self recieveLong: &size]) {
			NSLog(@"Error while reading packet size");
			break;
		}
		
		
		// get channel names
		 int i;
		BOOL problem = NO;
		[channelNames removeAllObjects];
		
		NSLog(@"Adding channels:");
		for (i = 0; i < size; ++i)
		{
			 int stringLength;
			char c[255];
			char *p = c;
			
			if(![self recieveLong: &stringLength]) {
				NSLog(@"Error receiving string length");
				problem = YES;
				break;
			}
			
			if(![self recieveWithBuffer:(UInt8 *)c andSize:stringLength]) {
				NSLog(@"Error receiving string");
				problem = YES;
				break;
			}
			
			p += stringLength; // 64-Bit warning TODO
			*p = 0; // zero-terminate string
			
			NSString *channelName = @(c);
			[channelNames addObject:channelName];	
			//printf("%s\n", [channelName UTF8String]);
		}
		
		if (problem) break; // yeah, kinda ugly :)
		done = YES;
		
		// build up the TrackingList - setters are atomic
		NSMutableArray *buildupTrackingArray = [[NSMutableArray alloc] init];
		NSMutableArray *buildupCheckArray = [[NSMutableArray alloc] init];
		NSUInteger currentIndex = -1;
		for (NSString *channelName in channelNames)
		{
			++currentIndex;
			
			// divide string to get marker name and coordinate name
			// string can be one of the following:
			// [SUBJECT:]MARKER_NAME<CODE>
			// [SUBJECT:]BODY_NAME<CODE>
			// Time X fps<F>
			// or some kinematic info - but we'll skip that for now TODO
			
			// we try to distinguish the channel types by their code!
			
			NSArray *dividedString = [channelName componentsSeparatedByCharactersInSet:
									  [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
			NSString *code = dividedString[1];
			NSString *entityName = dividedString[0];
			// we could do some fancy stuff now e.g. storing the appropriate selectors in a dictionary with the codes for keys...
			// ...but I think we are better off with a quick'n dirty if-else
			// TODO: check if strings can be compared via isEqual: because that happens when looking up the index of the entityName below
			
			//printf("Decoding channel name:");
			//printf("%s\n", [channelName UTF8String]);
			
			if ([code isEqualToString:@"F"]) // time channel
			{
				// get the fps number
				long long_fps = [[entityName componentsSeparatedByString:@" "][1] integerValue];
				int fps = (int)long_fps;
                self.trackingList.fpsSent = @(fps);
				self.trackingList.timeChannel = currentIndex;
			}
			else if ([code hasPrefix:@"P-"]) // we've got the Pos for a marker
			{
				// first, check if we have created the object for the marker already
				NSInteger index = [buildupCheckArray indexOfObject:entityName];
				
				ViconMarker *marker;
				if(index == NSNotFound) {
					// we need to create a new object for the marker and fill in the name
					marker = [[ViconMarker alloc] initWithEntityName:entityName];
					[buildupTrackingArray addObject:marker];
					[buildupCheckArray addObject:entityName];
				} else
					// we already have an object for the marker - just have to update it
					marker = buildupTrackingArray[index];
				
				// now fill in the new info
				if ([code hasSuffix:@"X"])
					marker.xChannel = currentIndex;
				else if ([code hasSuffix:@"Y"])
					marker.yChannel = currentIndex;
				else if ([code hasSuffix:@"Z"])
					marker.zChannel = currentIndex;
				else if ([code hasSuffix:@"O"])
					marker.occChannel = currentIndex;
				else {
					NSLog(@"Unknown Code:");
					NSLog(@"%@", code);
					break; // bail out
				}
			} // end marker info handling
			else if ([code hasPrefix:@"t-"] || [code hasPrefix:@"a-"]) // we've got the Pos or Rot for a body
			{
				// first, check if we have created the object for the marker already
				NSInteger index = [buildupCheckArray indexOfObject:entityName];
				
				ViconBody *body;
				if(index == NSNotFound) {
					// we need to create a new object for the marker and fill in the name
					body = [[ViconBody alloc] initWithEntityName:entityName];
					[buildupTrackingArray addObject:body];
					[buildupCheckArray addObject:entityName];
				} else
					// we already have an object for the marker - just have to update it
					body = buildupTrackingArray[index];
				
				// now fill in the new info
				
				if ([code hasPrefix:@"t"]) // translation info
				{
					if ([code hasSuffix:@"X"])
						body.xChannel = currentIndex;
					else if ([code hasSuffix:@"Y"])
						body.yChannel = currentIndex;
					else if ([code hasSuffix:@"Z"])
						body.zChannel = currentIndex;
					else {
						NSLog(@"Unknown Code!");
						break; // bail out
					}
				} else { // rotation info
					if ([code hasSuffix:@"X"])
						body.xrChannel = currentIndex;
					else if ([code hasSuffix:@"Y"])
						body.yrChannel = currentIndex;
					else if ([code hasSuffix:@"Z"])
						body.zrChannel = currentIndex;
					else {
						NSLog(@"Unknown Code!");
						break; // bail out
					}
				}
			} // end body info handling
			else
				NSLog(@"Encountered unknown code: %@", code);
			
			
			
		} // end parsing channel names
		
		// now paste the newly built tracking array into the tracking list object
		self.trackingList.trackingList = buildupTrackingArray;
		self.trackingList.invalid = NO;
        
		
	} // end while !done loop
		
	if (!done) // this happens if we bailed out
	{
		// we left the loop because of some problem
		// Close the streams
		
		// #################################
		// THESE ARE CALLED TWICE AND CAUSE BAD ACCESS
		//####################################
		
        //CFReadStreamClose(readStream);
        //CFWriteStreamClose(writeStream);
		//CFRelease(readStream);
		//CFRelease(writeStream);
		
		return NO;
	}
	
	return YES;
}

-(BOOL)recieveWithBuffer:(UInt8 *)pBuffer andSize:(int)bufferSize;
{
	UInt8 *p = pBuffer;
	UInt8 *e = pBuffer + bufferSize;
	
	BOOL result;
	
	while(p != e) {
		
		result = CFReadStreamRead(readStream, p, e-p);
		
		if(result == -1)
			return NO;
		
		p += result;
	}
	
	return YES;
}

-(BOOL)recieveLong:( int *)Val;
{
	return [self recieveWithBuffer:(UInt8 *)Val andSize:sizeof(*Val)];
}

-(BOOL)recieveULong:(unsigned  int *)Val;
{
	return [self recieveWithBuffer:(UInt8 *)Val andSize:sizeof(*Val)];
}

-(BOOL)recieveDouble:(double *)Val;
{
	return [self recieveWithBuffer:(UInt8 *)Val andSize:sizeof(*Val)];
}


@end
