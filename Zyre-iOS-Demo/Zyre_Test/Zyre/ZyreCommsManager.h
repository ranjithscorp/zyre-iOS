//
//  ZyreCommsManager.h
//  Zyre_Test
//
//  Created by Ranjith C on 27/06/16.
//  Copyright © 2016 Ranjith C. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "zyre.h"

@interface ZyreCommsManager : NSObject

@property zyre_t * zyre;
@property const char * grpName;
@property BOOL listenToEventsFlag;
@property BOOL isZyreReady;

-(BOOL) initZyre:(BOOL) delayedInit;
-(BOOL) startZyre;
-(BOOL) stopZyre;
-(BOOL) closeZyre;
-(BOOL) sendToAllZyre:(NSString *) msgString;
-(BOOL) sendToOneZyre:(NSString *) msgString nodeID:(NSString *) nodeID;
-(const char *) getGroup;
-(BOOL) setGroup:(const char *)groupName;
-(zyre_t *) getZyre;

@end
