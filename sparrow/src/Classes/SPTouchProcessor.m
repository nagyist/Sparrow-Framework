//
//  SPTouchProcessor.m
//  Sparrow
//
//  Created by Daniel Sperl on 03.05.09.
//  Copyright 2009 Incognitek. All rights reserved.
//

#import "SPTouchProcessor.h"
#import "SPMacros.h"
#import "SPTouchEvent.h"
#import "SPTouch.h"
#import "SPTouch_Internal.h"
#import "SPPoint.h"
#import "SPMatrix.h"
#import "SPDisplayObjectContainer.h"

#define MULTITAP_TIME 0.25f
#define MULTITAP_DIST 25

@implementation SPTouchProcessor

@synthesize root = mRoot;

- (id)initWithRoot:(SPDisplayObjectContainer*)root
{    
    if (self = [super init])
    {        
        mRoot = [root retain];
        mCurrentTouches = [[NSMutableSet alloc] initWithCapacity:2];
    }
    return self;
}

- (void)processTouches:(NSSet*)touches
{
    SP_CREATE_POOL(pool);    
    
    // process new touches
    for (SPTouch *touch in touches)
    {
        SPTouch *currentTouch = nil;
               
        for (SPTouch *existingTouch in mCurrentTouches)
        {
            if ((existingTouch.globalX == touch.previousGlobalX &&
                 existingTouch.globalY == touch.previousGlobalY) ||
                (existingTouch.globalX == touch.globalX &&
                 existingTouch.globalY == touch.globalY))
            {
                // existing touch; update values
                existingTouch.timestamp = touch.timestamp;
                existingTouch.previousGlobalX = touch.previousGlobalX;
                existingTouch.previousGlobalY = touch.previousGlobalY;
                existingTouch.globalX = touch.globalX;
                existingTouch.globalY = touch.globalY;
                existingTouch.phase = touch.phase;
                existingTouch.tapCount = touch.tapCount;
                
                if (!existingTouch.target.stage)
                {
                    // target could have been removed from stage -> find new target in that case
                    SPPoint *touchPosition = [SPPoint pointWithX:touch.globalX y:touch.globalY];
                    existingTouch.target = [mRoot hitTestPoint:touchPosition forTouch:YES];       
                }
               
                currentTouch = existingTouch;
                break;
            }
        }
        
        if (!currentTouch)
        {
            // new touch!
            currentTouch = [SPTouch touch];
            currentTouch.timestamp = touch.timestamp;
            currentTouch.globalX = touch.globalX;
            currentTouch.globalY = touch.globalY;
            currentTouch.previousGlobalX = touch.previousGlobalX;
            currentTouch.previousGlobalY = touch.previousGlobalY;
            currentTouch.phase = touch.phase;
            currentTouch.tapCount = touch.tapCount;
            SPPoint *touchPosition = [SPPoint pointWithX:touch.globalX y:touch.globalY];
            currentTouch.target = [mRoot hitTestPoint:touchPosition forTouch:YES];
            [mCurrentTouches addObject:currentTouch];
        }        
    }
    
    // dispatch events     
    NSSet *immutableSet = [[NSSet alloc] initWithSet:mCurrentTouches];
    for (SPTouch *touch in immutableSet)
    {       
        SPTouchEvent *touchEvent = [[SPTouchEvent alloc] initWithType:SP_EVENT_TYPE_TOUCH 
                                                              touches:immutableSet];
        [touch.target dispatchEvent:touchEvent];
        [touchEvent release];
    }    
    [immutableSet release];
    
    // now remove all touches that ended or were cancelled    
    NSMutableSet *remainingTouches = [[NSMutableSet alloc] initWithCapacity:mCurrentTouches.count];
    for (SPTouch *touch in mCurrentTouches)
    {        
        if (touch.phase != SPTouchPhaseEnded && touch.phase != SPTouchPhaseCancelled)            
            [remainingTouches addObject:touch];        
    }    
    [mCurrentTouches release];    
    mCurrentTouches = remainingTouches;    

    SP_RELEASE_POOL(pool);
}

#pragma mark -

- (void) dealloc
{
    [mRoot release];
    [mCurrentTouches release];
    [super dealloc];
}

@end
