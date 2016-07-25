//
//  ViewController.m
//  iOSViconApp
//
//  Created by Kashyap Todi on 4/26/13.
//  Copyright (c) 2013 Media Computing Group - RWTH Aachen University. All rights reserved.
//

#import "ViewController.h"
#import "ViconController.h"
@interface ViewController ()
{
    NSString *connectButtonTitle, *statusLabelText;
    BOOL connectButtonEnabled;
}
@property (weak, nonatomic) IBOutlet UITextView *trackingListView;
@property (strong, nonatomic) NSMutableString *viconObjectDetails;
@property (strong, nonatomic) ViconController *viconController;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end

@implementation ViewController

- (ViconController *) viconController
{
    if (!_viconController)
    {
        _viconController = [[ViconController alloc] init];
        [self.viconController addObserver:self forKeyPath:@"connected" options:NSKeyValueObservingOptionNew context:nil];
        [self.viconController addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        [self.viconController addObserver:self forKeyPath:@"newFrameReceived" options:NSKeyValueObservingOptionNew context:nil];
        [self.viconController addObserver:self forKeyPath:@"enableConnection" options:NSKeyValueObservingOptionNew context:nil];
    }
    return _viconController;
}

- (IBAction)connectButtonPressed:(UIButton *)sender
{
    [self.viconController connectOrDisconnectVicon];
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    
    if ([keyPath isEqual:@"newFrameReceived"]) {
        //This is called each time the Vicon Controller receives a new data frame.
        //Access the data by using the property "trackingList" (NSArray) of the ViconController
        self.viconObjectDetails = [[NSMutableString alloc] initWithCapacity:1000];
        for (ViconObject *viconObj in self.viconController.trackingList)
        {        // Iterate through all ViconObjects.
            if ([viconObj isKindOfClass:[ViconBody class]] && viconObj.zPos!=0.0)
                [self.viconObjectDetails appendFormat:@"\n%@:\t%.2f, %.2f, %.2f",viconObj.name,viconObj.xPos,viconObj.yPos,viconObj.zPos];
            
        }

    }
    [self updateUI] ;
}

//Update UI elements based on the state of the ViconController.
- (void) updateUI
{
    dispatch_async(dispatch_get_main_queue(), ^(){
    
        self.connectButton.enabled = self.viconController.enableConnection;
        self.connectButton.alpha = self.viconController.enableConnection? 1.0 : 0.3;
        [self.connectButton setTitle:self.viconController.connected?@"Disconnect":@"Connect"
                            forState:UIControlStateNormal];
        
        self.statusLabel.text = self.viconController.status;
        
        self.trackingListView.text = self.viconObjectDetails;
    });
}

@end
