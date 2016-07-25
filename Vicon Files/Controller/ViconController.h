//
//  ViconController.h
//
//  Created by Kashyap Todi on 4/1/13.
//  Copyright (c) 2013 Media Computing Group - RWTH Aachen University. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "ViconServerConnection.h"

@interface ViconController : NSObject

@property (readonly, nonatomic, strong) NSMutableString *viconObjectNames;
@property (readonly, nonatomic) BOOL connected;
@property (strong, nonatomic, readonly) NSString *status;
@property (readonly, nonatomic) BOOL enableConnection;
@property (readonly, nonatomic) BOOL newFrameReceived;
@property (readonly, strong, nonatomic) NSArray *trackingList;

- (void) connectOrDisconnectVicon;

@end
