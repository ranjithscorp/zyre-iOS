//
//  ViewController.m
//  Zyre_Test
//
//  Created by Ranjith C on 15/06/16.
//  Copyright © 2016 Ranjith C. All rights reserved.
//

#import "ViewController.h"
#import "zyre.h"
@interface ViewController ()
@property (nonatomic, strong) ZyreCommsManager * zyreManager;
@property (weak, nonatomic) IBOutlet UILabel *lblMessage;
@property (weak, nonatomic) IBOutlet UIButton *btnShowPeers;
@property (weak, nonatomic) IBOutlet UIButton *btnShout;
@property (weak, nonatomic) IBOutlet UIButton *btnReceiveText;
@property (weak, nonatomic) IBOutlet UITextField *txtField;
@property (nonatomic, strong) NSString * msgString;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.txtField.text = @"Test Message";
    self.msgString = @"";
    self.lblMessage.text = @"";
    [self.lblMessage sizeToFit];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    [self startZyre];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(zyreEventRecieved:) name:@"onZyreEventRecieved" object:nil];
    // Do any additional setup after loading the view, typically from a nib.
}

// Initialize Zyre
-(void)startZyre {
    self.zyreManager = [[ZyreCommsManager alloc] init];
    [self.zyreManager initZyre:YES];
    [self.zyreManager startZyre];
    self.lblMessage.text = @"Zyre Joined: Bezirk_Group";
}

- (IBAction)btnShowDetails:(id)sender {
    zyre_t * zyre = [self.zyreManager getZyre];
    zyre_print (zyre);
}

// Sends the message as SHOUT in the Group
-(IBAction)btnShoutTapped:(id)sender {
    self.msgString = [NSString stringWithFormat:@"%@", self.txtField.text];
    [self.zyreManager sendToAllZyre:self.msgString];
}

// Clear Text displayed
- (IBAction)btnClearTapped:(id)sender {
    self.lblMessage.text = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dismissKeyboard {
    [self.txtField resignFirstResponder];
}

#pragma mark ZYRE EVENT CALLBACK

-(void) zyreEventRecieved:(NSNotification *) sender {
    NSDictionary * dictRecieved = sender.object;
    if ([dictRecieved objectForKey:@"message"]) {
        self.lblMessage.text = [NSString stringWithFormat:@"%@ Recieved: %@", [dictRecieved objectForKey:@"event"],[dictRecieved objectForKey:@"message"]];
    }
    else if ([dictRecieved objectForKey:@"group"]) {
        self.lblMessage.text = [NSString stringWithFormat:@"Peer Joined: %@", [dictRecieved objectForKey:@"group"]];
    }
    NSLog(@"Message Recieved %@",sender.object);
}

@end
