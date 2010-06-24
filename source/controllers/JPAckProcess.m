// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckProcess.h"
#import "JPAckProcess+Parsing.h"
#import "JPAckResultSource.h"

@interface JPAckProcess ()
@property(retain) NSMutableData* trailing;
@property(retain) NSMutableData* errorData;
@property(retain) JPAckResultSource* ackResult;
@property(retain) NSTask* ackTask;
- (NSData*)trailingAndCurrent:(NSData*)data;
- (void)handleStateEvent:(NSInteger)eventType;
@end

@implementation JPAckProcess

NSString * const JPAckProcessComplete = @"JPAckProcessComplete";

@synthesize errorData;
@synthesize trailing;
@synthesize ackTask;
@synthesize ackResult;

enum {
  ackInitial        = 0,
  ackStdOutClosed   = 1<<0,
  ackStdErrClosed   = 1<<1,
  ackTerminated     = 1<<2,
  ackComplete       = (ackStdOutClosed | ackStdErrClosed | ackTerminated)
} ackStates;


- (id)initWithResultHolder:(JPAckResultSource*)resultHolder
{
  if (self = [super init])
  {
    ackTask = nil;
    errorData = nil;
    trailing = nil;
    ackResult = [resultHolder retain];
  }
  return self;
}

- (void)invokeWithTerm:(NSString*)term path:(NSString*)path searchFolder:(NSString*)searchFolder literal:(BOOL)literal nocase:(BOOL)nocase words:(BOOL)words context:(BOOL)context symlinks:(BOOL)symlinks folderPattern:(NSString*)folderPattern options:(NSArray*)options
{
  ackState = ackInitial;
  [self.ackResult clearContents];
  [self.ackResult searchingFor:term inRoot:path inFolder:searchFolder];

  self.ackTask = [[[NSTask alloc] init] autorelease];

  NSString* ackmateAck = [[[NSBundle bundleForClass:self.class] resourcePath] stringByAppendingPathComponent:@"ackmate_ack"];

  [self.ackTask setCurrentDirectoryPath:path];

  [self.ackTask setLaunchPath:@"/usr/bin/env"];
  NSMutableArray* args = [NSMutableArray arrayWithObjects:@"perl", @"-CADS", ackmateAck, @"--ackmate", nil];

  if (literal) [args addObject:@"--literal"];
  if (words) [args addObject:@"--word-regexp"];
  if (context) [args addObject:@"--context"];

  if (symlinks)
    [args addObject:@"--follow"];
  else
    [args addObject:@"--nofollow"];

  if (nocase)
    [args addObject:@"--ignore-case"];
  else
    [args addObject:@"--nosmart-case"];

  if (folderPattern)
  {
    [args addObject:@"--ackmate-dir-filter"];
    [args addObject:folderPattern];
  }

  for (NSString* typeOption in options)
    [args addObject:[NSString stringWithFormat:@"%@%@", ([typeOption hasPrefix:@"-"]) ? @"" : @"--", typeOption]];

  [args addObject:@"--match"];
  [args addObject:term];
  [args addObject:(searchFolder) ? searchFolder : path];

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
      [ackResult parsedError:[[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease]];

    [ackResult updateStats];
    [[NSNotificationCenter defaultCenter] postNotificationName:JPAckProcessComplete object:self userInfo:nil];
  }
}

- (void)resultData:(NSNotification*)notification
{
  NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] > 0)
  {
    [self parseData:data];
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

- (void)parseData:(NSData*)data
{
  [self consumeInputLines:[self trailingAndCurrent:data]];
}

- (void)saveTrailing:(char*)bytes length:(NSUInteger)length
{
  self.trailing = [NSMutableData dataWithBytes:bytes length:length];
}

- (NSData*)trailingAndCurrent:(NSData*)data
{
  if (!self.trailing)
    return data;

  NSMutableData* tandc = [[self.trailing retain] autorelease];
  self.trailing = nil;
  [tandc appendData:data];
  return tandc;
}

- (void)terminateImmediately:(BOOL)immediately
{
  [self.ackTask terminate];

  // If immediately then we must clean up any references
  // that might be left dangling and don't worry about lost
  // callbacks - they don't matter any more because we're about
  // to be completely deallocated
  if (immediately)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [ackResult release], ackResult = nil;
  }
}

- (void)dealloc
{
  [errorData release], errorData = nil;
  [trailing release], trailing = nil;
  [ackTask release], ackTask = nil;
  [ackResult release], ackResult = nil;
  [super dealloc];
}

@end
