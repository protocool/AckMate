// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "AckMatePlugin.h"
#import "JPAckWindowController.h"

@interface AckMatePlugin ()
- (void)installMenuItems;
- (NSMutableDictionary*)preferencesForProjectRoot:(NSString*)projectRoot;
- (void)loadPluginPreferences;
- (void)savePluginPreferences;
- (id)firstProjectController;
- (NSString*)directoryForProject:(id)projectController;
@end

@implementation AckMatePlugin

- (id)initWithPlugInController:(id <TMPlugInController>)aController
{
  if (self = [self init])
  {
    NSApp = [NSApplication sharedApplication];
    ackWindows = [[NSMutableDictionary alloc] initWithCapacity:0];
    [self installMenuItems];
    [self loadPluginPreferences];

    // Load up our bundle images
    NSBundle* pluginBundle = [NSBundle bundleForClass:[self class]];
    NSString* collapseImagePath = [pluginBundle pathForResource:@"ackmateCollapse" ofType:@"pdf"];
    NSImage* collapseImage = [[NSImage alloc] initWithContentsOfFile:collapseImagePath];
    [collapseImage setName:@"ackmateCollapse"];
    NSString* expandImagePath = [pluginBundle pathForResource:@"ackmateExpand" ofType:@"pdf"];
    NSImage* expandImage = [[NSImage alloc] initWithContentsOfFile:expandImagePath];
    [expandImage setName:@"ackmateExpand"];
  }
  return self;
}

- (BOOL)validateMenuItem:(NSMenuItem*)item
{
  if ([item action] == @selector(findWithAck:))
    return [self firstProjectController] ? YES : NO;

  return YES;
}

- (id)firstProjectController
{
  for (NSWindow *w in [[NSApplication sharedApplication] orderedWindows])
  {
    id wc = [w windowController];

    if ([[wc className] isEqualToString:@"OakDocumentController"])
      return nil; // more frontmost non-project editing window...

    if ([[wc className] isEqualToString:@"OakProjectController"])
      return wc;
  }
  return nil;
}

- (void)findWithAck:(id)sender
{
  NSString* directory = nil;
  id tmProjectController = [self firstProjectController];

  if (tmProjectController)
    directory = [self directoryForProject:tmProjectController];

  if (directory)
  {
    JPAckWindowController* ackWindow = [ackWindows objectForKey:directory];
    if (!ackWindow)
    {
      [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(projectWindowWillClose:) name:NSWindowWillCloseNotification object:[tmProjectController window]];
      NSMutableDictionary* pprefs = [self preferencesForProjectRoot:directory];
      ackWindow = [[[JPAckWindowController alloc] initWithProjectDirectory:directory controller:tmProjectController preferences:pprefs] autorelease];
      [ackWindows setObject:ackWindow forKey:directory];
    }

    [ackWindow showAndActivate];
  }
}

- (NSString*)directoryForProject:(id)projectController
{
  NSDictionary* d = [projectController environmentVariables];
  return [d objectForKey:@"TM_PROJECT_DIRECTORY"];
}

- (void)projectWindowWillClose:(NSNotification*)notification
{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:[notification object]];
  id windowController = [[notification object] windowController];
  if ([[windowController className] isEqualToString:@"OakProjectController"])
  {
    NSString* closingProjectDir = [self directoryForProject:windowController];
    JPAckWindowController* existingAckController = [ackWindows objectForKey:closingProjectDir];
    if (existingAckController)
      [existingAckController cleanupImmediately:YES];

    [ackWindows removeObjectForKey:closingProjectDir];
  }
  [self savePluginPreferences];
}

- (void)installMenuItems
{
  NSString *editTitle = NSLocalizedString(@"Edit", @"");
  id editMenu = [[[NSApp mainMenu] itemWithTitle:editTitle] submenu];
  if (editMenu)
  {
    NSString *findTitle = NSLocalizedString(@"Find", @"");
    id findMenu = [[editMenu itemWithTitle:findTitle] submenu];

    if (findMenu)
    {
      int index = 0;
      int separators = 0;
      NSArray *items = [findMenu itemArray];
      for (separators = 0; index != [items count] && separators != 1; index++)
        separators += [[items objectAtIndex:index] isSeparatorItem] ? 1 : 0;

      NSString *title = NSLocalizedString(@"Search Project With AckMate...", @"");

      // don't submit patches for the key equivalent, just set your own in
      // system preferences under keyboard / keyboard shortcuts
      NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:title action:@selector(findWithAck:) keyEquivalent:@"f"];
      [menuItem setKeyEquivalentModifierMask:(NSAlternateKeyMask | NSCommandKeyMask | NSControlKeyMask)];
      [menuItem setTarget:self];
      [findMenu insertItem:menuItem atIndex:index ? index-1 : 0];
      [menuItem release];
    }
  }
}

- (NSMutableDictionary*)preferencesForProjectRoot:(NSString*)projectRoot
{
  NSMutableDictionary* rval = [ackPreferences objectForKey:projectRoot];
  if (!rval)
  {
    rval = [NSMutableDictionary dictionary];
    [ackPreferences setObject:rval forKey:projectRoot];
    [rval setObject:[NSNumber numberWithBool:YES] forKey:kJPAckShowContext];
    [rval setObject:[NSNumber numberWithBool:YES] forKey:kJPAckFollowSymlinks];
    [rval setObject:[NSNumber numberWithBool:YES] forKey:kJPAckFolderReferences];
  }

  // Add a default value of YES for kJPAckShowAdvanced
  if (![rval objectForKey:kJPAckShowAdvanced])
    [rval setObject:[NSNumber numberWithBool:YES] forKey:kJPAckShowAdvanced];

  return rval;
}

- (void)loadPluginPreferences
{
  NSString* pluginDomain = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
  ackPreferences = [[[NSUserDefaults standardUserDefaults] persistentDomainForName:pluginDomain] mutableCopy];

  if (!ackPreferences)
    ackPreferences = [[NSMutableDictionary dictionary] retain];

  for (NSString* projectRoot in [ackPreferences allKeys])
  {
    NSDictionary* projectPrefs = [[[ackPreferences objectForKey:projectRoot] mutableCopy] autorelease];
    [ackPreferences setObject:projectPrefs forKey:projectRoot];
  }
}

- (void)savePluginPreferences
{
  NSString* pluginDomain = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
  if (ackPreferences)
    [[NSUserDefaults standardUserDefaults] setPersistentDomain:ackPreferences forName:pluginDomain];
}

- (void)dealloc
{
  [ackPreferences release], ackPreferences = nil;
  [ackWindows release], ackWindows = nil;
  [super dealloc];
}
@end
