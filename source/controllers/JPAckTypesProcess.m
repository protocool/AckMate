// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckTypesProcess.h"

@interface JPAckTypesProcess ()
@property(retain) NSMutableData* typesData;
@property(retain) NSMutableData* errorData;
@property(retain) NSTask* ackTask;
- (void)handleStateEvent:(NSInteger)eventType;
@end

@implementation JPAckTypesProcess

NSString * const JPAckTypesProcessComplete = @"JPAckTypesProcessComplete";
NSString * const kJPAckTypesResult = @"kJPAckTypesResult";

@synthesize typesData;
@synthesize errorData;
@synthesize ackTask;

enum {
  ackInitial        = 0,
  ackStdOutClosed   = 1<<0,
  ackStdErrClosed   = 1<<1,
  ackTerminated     = 1<<2,
  ackComplete       = (ackStdOutClosed | ackStdErrClosed | ackTerminated)
} ackStates;


- (id)init
{
  if (self = [super init])
  {
    errorData = nil;
    typesData = nil;
    ackTask = nil;
  }
  return self;
}

- (void)invokeWithPath:(NSString*)path options:(NSArray*)options
{
  ackState = ackInitial;

  self.ackTask = [[[NSTask alloc] init] autorelease];

  NSString* ackmateAck = [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"ackmate_ack"];

  [self.ackTask setCurrentDirectoryPath:path];

  [self.ackTask setLaunchPath:@"/usr/bin/env"];
  NSMutableArray* args = [NSMutableArray arrayWithObjects:@"perl", ackmateAck, nil];

  for (NSString* typeOption in options)
  {
    if ([typeOption hasPrefix:@"--type-set="] || [typeOption hasPrefix:@"--type-add="])
      [args addObject:typeOption];
  }

  [args addObject:@"--ackmate-types"];

  [self.ackTask setArguments:args];

  NSPipe* stdoutPipe = [NSPipe pipe];
  NSPipe* stderrPipe = [NSPipe pipe];

  [self.ackTask setStandardInput:[NSFileHandle fileHandleWithNullDevice]];
  [self.ackTask setStandardError:stderrPipe];
  [self.ackTask setStandardOutput:stdoutPipe];

  [self.ackTask launch];

  NSFileHandle* stdoutFileHandle = [stdoutPipe fileHandleForReading];
  NSFileHandle* stderrFileHandle = [stderrPipe fileHandleForReading];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resultData:) name:NSFileHandleReadCompletionNotification object:stdoutFileHandle];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorData:) name:NSFileHandleReadCompletionNotification object:stderrFileHandle];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskEnded:) name:NSTaskDidTerminateNotification object:ackTask];

  [stdoutFileHandle readInBackgroundAndNotify];
  [stderrFileHandle readInBackgroundAndNotify];
}

- (void)handleStateEvent:(NSInteger)eventType
{
  ackState |= eventType;
  if (ackState == ackComplete)
  {
    self.ackTask = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    if (errorData)
    {
      NSLog(@"AckMate: error reading ack types: %@", [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease]);
      [[NSNotificationCenter defaultCenter] postNotificationName:JPAckTypesProcessComplete object:self userInfo:nil];
    }
    else
    {
      NSString* returnedTypes = [[[NSString alloc] initWithData:typesData encoding:NSUTF8StringEncoding] autorelease];
      NSArray* typesArray = [returnedTypes componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
      NSDictionary* info = [NSDictionary dictionaryWithObject:typesArray forKey:kJPAckTypesResult];
      [[NSNotificationCenter defaultCenter] postNotificationName:JPAckTypesProcessComplete object:self userInfo:info];
    }
  }
}

- (void)resultData:(NSNotification*)notification
{
  NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] > 0)
  {
    if (!typesData)
      self.typesData = [NSMutableData data];

    [typesData appendData:data];
    [[notification object] readInBackgroundAndNotify];
  }
  else
    [self handleStateEvent:ackStdOutClosed];
}

- (void)errorData:(NSNotification*)notification
{
  NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] > 0)
  {
    if (!errorData)
      self.errorData = [NSMutableData data];

    [errorData appendData:data];
    [[notification object] readInBackgroundAndNotify];
  }
  else
    [self handleStateEvent:ackStdErrClosed];
}

- (void)taskEnded:(NSNotification*)notification
{
  if ([notification object] == self.ackTask)
    [self handleStateEvent:ackTerminated];
}

- (void)terminate
{
  [self.ackTask terminate];
}

- (void)dealloc
{
  [errorData release], errorData = nil;
  [typesData release], typesData = nil;
  [ackTask release], ackTask = nil;
  [super dealloc];
}

@end
