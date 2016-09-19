//
//  AppDelegate.m
//  ChessGame
//
//  Created by songlong on 16/9/14.
//  Copyright © 2016年 Saber. All rights reserved.
//

#import "AppDelegate.h"
#import "GameViewController.h"
#import "PickerViewController.h"

static NSString * kWiTapBonjourType = @"_chessgame._tcp.";

@interface AppDelegate ()<NSNetServiceDelegate, PickerDelegate, NSStreamDelegate, GameViewControllerDelegate>

@property (nonatomic, strong) GameViewController *gameViewController;
@property (nonatomic, strong) PickerViewController *picker;
@property (nonatomic, strong) NSNetService *server;
@property (nonatomic, assign) BOOL isServerStarted;
@property (nonatomic, copy) NSString *registeredName;

@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, assign) NSInteger streamOpenCount;


@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.gameViewController = [[GameViewController alloc] init];
    self.gameViewController.delegate = self;
    self.window.rootViewController = self.gameViewController;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    self.server = [[NSNetService alloc] initWithDomain:@"local." type:kWiTapBonjourType name:[UIDevice currentDevice].name port:0];
    self.server.includesPeerToPeer = YES;
    self.server.delegate = self;
    [self.server publishWithOptions:NSNetServiceListenForConnections];
    self.isServerStarted = YES;
    
    [self setupForNewGame];
    

    
    return YES;
}

- (void)setupForNewGame {
    [self.gameViewController resetGame];
    [self closeStreams];
    
    if (!self.isServerStarted) {
        [self.server publishWithOptions:NSNetServiceListenForConnections];
        self.isServerStarted = YES;
    }
    
    [self presentPicker];
}

- (void)presentPicker {
    if (self.picker != nil) {
        [self.picker cancelConnect];
    } else {
        self.picker = [[PickerViewController alloc] init];
        self.picker.type = kWiTapBonjourType;
        self.picker.delegate = self;
        if (self.registeredName != nil) {
            [self startPicker];
        }
        [self.gameViewController presentViewController:self.picker animated:NO completion:nil];
    }
}

- (void)dismissPicker {
    assert(self.picker != nil);
    
    [self.gameViewController dismissViewControllerAnimated:NO completion:nil];
    [self.picker stop];
    self.picker = nil;
}

- (void)openStreams {
    assert(self.inputStream != nil);
    assert(self.outputStream != nil);
    assert(self.streamOpenCount == 0);
    
    [self.inputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    
    [self.outputStream setDelegate:self];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream open];
}

- (void)closeStreams {
    assert( (self.inputStream != nil) == (self.outputStream != nil) );
    if (self.inputStream != nil) {
        [self.inputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.inputStream close];
        self.inputStream = nil;
        
        [self.outputStream removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [self.outputStream close];
        self.outputStream = nil;
    }
    
    self.streamOpenCount = 0;
}

- (void)startPicker {
    assert(self.registeredName != nil);
    self.picker.localService = self.server;
    [self.picker start];
}



- (void)applicationDidEnterBackground:(UIApplication *)application {
    
    if (self.inputStream) {
        [self setupForNewGame];
    }
    
    [self.server stop];
    self.isServerStarted = NO;
    self.registeredName = nil;
    if (self.picker != nil) {
        [self.picker stop];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    
    assert(!self.isServerStarted);
    [self.server publishWithOptions:NSNetServiceListenForConnections];
    self.isServerStarted = YES;
    if (self.registeredName != nil) {
        [self startPicker];
    }
}

#pragma mark --- Delegate

- (void)pickerViewController:(PickerViewController *)controller connectToService:(NSNetService *)service {
    BOOL success;
    NSInputStream *inStream;
    NSOutputStream *outStream;
    assert(controller == self.picker);
#pragma unused(controller)
    assert(service != nil);
    assert(self.inputStream == nil);
    assert(self.outputStream == nil);
    
    success = [service getInputStream:&inStream outputStream:&outStream];
    if (!success) {
        [self setupForNewGame];
    } else {
        self.inputStream = inStream;
        self.outputStream = outStream;
        [self openStreams];
    }
}

- (void)pickerViewControllerDidCancelConnect:(PickerViewController *)controller {
#pragma unused(controller)
    [self closeStreams];
}

- (void)stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode {
    #pragma unused(stream)
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            self.streamOpenCount += 1;
            assert(self.streamOpenCount <= 2);
            
            if (self.streamOpenCount == 2) {
                [self dismissPicker];
                
                [self.server stop];
                self.isServerStarted = NO;
                self.registeredName = nil;
            }
        }
            break;
            
        case NSStreamEventHasSpaceAvailable:
        {
            assert(stream == self.outputStream);
            // do nothing
        } break;
            
       
        case NSStreamEventHasBytesAvailable:
        {
            uint8_t     b;
            NSInteger   bytesRead;
            
            assert(stream == self.inputStream);
            
            bytesRead = [self.inputStream read:&b maxLength:sizeof(uint8_t)];
            int d = (int)b;
            if (bytesRead <= 0) {
                
            } else {
                if (d > 225) {
                    [self.gameViewController remotePoint:d - 225];
                } else if (d >= 1 && d <= 225) {
                    [self.gameViewController remoteTouchOnItem:d];
                } else {
                    
                }

            }
        }
            break;
        default:
            assert(NO);
            // fall through
        case NSStreamEventErrorOccurred:
            // fall through
        case NSStreamEventEndEncountered: {
            [self setupForNewGame];
        } break;
    }
}

- (void)send:(uint8_t)message
{
    assert(self.streamOpenCount == 2);
    
    // Only write to the stream if it has space available, otherwise we might block.
    // In a real app you have to handle this case properly but in this sample code it's
    // OK to ignore it; if the stream stops transferring data the user is going to have
    // to tap a lot before we fill up our stream buffer (-:
    
    if ( [self.outputStream hasSpaceAvailable] ) {
        NSInteger   bytesWritten;
        
        
        bytesWritten = [self.outputStream write:&message maxLength:sizeof(message)];
        if (bytesWritten != sizeof(message)) {
            [self setupForNewGame];
        }
    }
}

- (void)gameViewControllerDidClose:(GameViewController *)controller {
    [self setupForNewGame];
}

- (void)gameViewController:(GameViewController *)controller localTouchOnItem:(NSInteger)index {
    [self send:(uint8_t) (index)];
}

- (void)gameViewController:(GameViewController *)controller localPoint:(NSInteger)point {
    [self send:(uint8_t) (225 + point)];
}

- (void)netServiceDidPublish:(NSNetService *)sender
{
    assert(sender == self.server);
#pragma unused(sender)
    
    self.registeredName = self.server.name;
    if (self.picker != nil) {
        // If our server wasn't started when we brought up the picker, we
        // left the picker stopped (because without our service name it can't
        // filter us out of its list).  In that case we have to start the picker
        // now.
        
        [self startPicker];
    }
}

- (void)netService:(NSNetService *)sender didAcceptConnectionWithInputStream:(NSInputStream *)inputStream outputStream:(NSOutputStream *)outputStream
{
    // Due to a bug <rdar://problem/15626440>, this method is called on some unspecified
    // queue rather than the queue associated with the net service (which in this case
    // is the main queue).  Work around this by bouncing to the main queue.
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        assert(sender == self.server);
#pragma unused(sender)
        assert(inputStream != nil);
        assert(outputStream != nil);
        
        assert( (self.inputStream != nil) == (self.outputStream != nil) );      // should either have both or neither
        
        if (self.inputStream != nil) {
            // We already have a game in place; reject this new one.
            [inputStream open];
            [inputStream close];
            [outputStream open];
            [outputStream close];
        } else {
            // Start up the new game.  Start by deregistering the server, to discourage
            // other folks from connecting to us (and being disappointed when we reject
            // the connection).
            
            [self.server stop];
            self.isServerStarted = NO;
            self.registeredName = nil;
            
            // Latch the input and output sterams and kick off an open.
            
            self.inputStream  = inputStream;
            self.outputStream = outputStream;
            
            [self openStreams];
        }
    }];
}

- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary *)errorDict
// This is called when the server stops of its own accord.  The only reason
// that might happen is if the Bonjour registration fails when we reregister
// the server, and that's hard to trigger because we use auto-rename.  I've
// left an assert here so that, if this does happen, we can figure out why it
// happens and then decide how best to handle it.
{
    assert(sender == self.server);
#pragma unused(sender)
#pragma unused(errorDict)
    assert(NO);
}


@end
