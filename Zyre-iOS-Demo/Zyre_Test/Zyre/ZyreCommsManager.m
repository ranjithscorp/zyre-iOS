//
//  ZyreCommsManager.m
//  Bezirk_Middleware
//
//  Created by Ranjith C on 27/06/16.
//  Copyright © 2016 Ranjith C. All rights reserved.
//

#import "ZyreCommsManager.h"

@implementation ZyreCommsManager
int delayedInitTime = 0; //in seconds

/**
 * initialize the zyre
 */
-(BOOL)initZyre:(BOOL)delayedInit {
    @try {
        //before initialization is ready, set flag as false
        self.isZyreReady = false;
        self.listenToEventsFlag = true;
        
        //init a new zyre context..
        self.zyre = zyre_new("iPhone");
        NSLog(@"Zyre is initialized but not yet ready..!!!");
        
        // delaying since zyre for android doesn't connect as fast as wifi available
        if (delayedInit == true) {
            [self delayZyreCreation];
        } else {
            self.isZyreReady = true;
        }
    } @catch (NSException *exception) {
        NSLog(@"Unable to load zyre comms. %@", exception);
        return false;
    }
    // create the zyre
    zyre_start(self.zyre);
    zyre_set_verbose (self.zyre);
    return true;
}

/**
 * Delay zyre creation
 */
-(void) delayZyreCreation {
    //adding the sleep as this will take time till new Zyre context is init
    @try {
        NSLog(@"zyre init : waiting for %i seconds before init",delayedInitTime);
        [NSThread sleepForTimeInterval:delayedInitTime];
        self.isZyreReady = true;
        NSLog(@"Zyre Initialization is Complete..!!!");
    } @catch (NSException *exception) {
        NSLog(@"Thread Interupted while initZyre");
    }
}

/**
 * start the zyre
 */
-(BOOL)startZyre {
    if (self.zyre != nil) {
        
        // join the group
        self.grpName = "BEZIRK_GROUP";
        zyre_join(self.zyre, self.grpName);
        
        //update flag
        self.listenToEventsFlag = true;
        
        @try {
            // start the receiver
            [self performSelectorInBackground:@selector(listenForMessages) withObject:nil];
        } @catch (NSException *exception) {
            NSLog(@"Exception while starting the thread: %@", exception);
            return false;
        }
    } else {
        NSLog(@"zyre not initialized");
    }
    return true;
}

/**
 * start Listening for recieving messages
 */
-(void) listenForMessages {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        zmsg_t *zmsg = zyre_recv (self.zyre);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (zmsg) {
                // pop data off of the zmsg stack to build our return object
                NSString *event = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)];
                NSString *peer = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)];
                NSString *name = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)]; // not using this now, just remove from stack
                NSString *group = NULL;
                NSString *message = NULL;
                name = nil;
                
                // return data as a string
                //NSString * msgString = @"";
                NSDictionary * dict = nil;
                // populate a dictionary object to be returned
                if ([event isEqualToString:@"SHOUT"]) {
                    group = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)];
                    message = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)];
                    dict = [[NSDictionary alloc] initWithObjectsAndKeys:event,@"event",peer,@"peer", group, @"group", message, @"message", nil];
                    //msgString = [NSString stringWithFormat:@"event::%@|peer::%@|group::%@|message::%@", event, peer, group, message];
                }
                else if ([event isEqualToString:@"WHISPER"]) {
                    message = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)];
                    dict = [[NSDictionary alloc] initWithObjectsAndKeys:event,@"event",peer,@"peer", message, @"message", nil];
                    //msgString = [NSString stringWithFormat:@"event::%@|peer::%@|group::|message::%@", event, peer, message];
                }
                else if ([event isEqualToString:@"JOIN"]) {
                    group = [NSString stringWithFormat:@"%s",zmsg_popstr (zmsg)];
                    dict = [[NSDictionary alloc] initWithObjectsAndKeys:event,@"event",peer,@"peer", group, @"group", nil];
                    //msgString = [NSString stringWithFormat:@"event::%@|peer::%@|group::%@|message::", event, peer, group];
                }
                else {
                    //dict = [[NSDictionary alloc] initWithObjectsAndKeys:event,@"event",peer,@"peer", nil];
                    //msgString = [NSString stringWithFormat:@"event::%@|peer::%@|group::|message::", event, peer];
                }
                zmsg_destroy ((zmsg_t **) &zmsg);
                if (dict!=nil) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"onZyreEventRecieved" object:dict];
                }
            }
            else {
                NSLog(@"No messages");
            }
        });
        if (self.listenToEventsFlag) {
            [self performSelectorInBackground:@selector(listenForMessages) withObject:nil];
        }
    });
}

/**
 * stop the zyre
 */
-(BOOL)stopZyre {
    //stop the listener servcie
    self.listenToEventsFlag = false;
    return [self closeZyre];
}

// destroy zyre instance
-(BOOL)closeZyre {
    @try {
        if (self.zyre != nil) {
            zyre_destroy((zyre_t **) self.zyre);
            return true;
        }
        self.zyre = nil;
    } @catch (NSException *exception) {
        NSLog(@"Error in stopping zyre: %@", exception);
    }
    return false;
}

// send zyre SHOUT
-(BOOL)sendToAllZyre:(NSString *)msgString {
    // in zyre we are sending ctrl and event in same. isEvent is ignored
    
    if (self.zyre != nil) {
        zmsg_t* msg = zmsg_new();
        const char * string = [msgString UTF8String];
        zmsg_addstr(msg,string);
        zyre_shout(self.zyre, self.grpName, &msg);
        NSLog(@"Shouted message to group : >> %s", self.grpName);
        NSLog(@"Multi-cast size : >> %lu", (unsigned long)msgString.length);
        zmsg_destroy ((zmsg_t **) &msg);
    }
    else {
        NSLog(@"zyre not initialized");
        return false;
    }
    return true;
}

// send zyre WHISPER
-(BOOL)sendToOneZyre:(NSString *)msgString nodeID:(NSString *)nodeID {
    // in zyre we are sending ctrl and event in same. isEvent is ignored
    if (self.zyre != nil) {
        zmsg_t* msg = zmsg_new();
        const char * string = [msgString UTF8String];
        zmsg_addstr(msg,string);
        const char * peerID = [nodeID UTF8String];
        //send to the specific node
        zyre_whisper(self.zyre, peerID, &msg);
        NSLog(@"Unicast size : >> %lu  data >> %@", (unsigned long)msgString.length, msgString);
        zmsg_destroy ((zmsg_t **) &msg);
    }
    else {
        NSLog(@"zyre not initialized");
        return false;
    }
    return true;
}

-(const char *)getGroup {
    return self.grpName;
}

-(BOOL)setGroup:(const char *)groupName {
    self.grpName = groupName;
    return true;
}

-(zyre_t *)getZyre {
    return self.zyre;
}

@end
