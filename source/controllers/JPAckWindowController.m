// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckWindowController.h"
#import "JPAckResultSource.h"
#import "JPAckProcess.h"
#import "JPAckTypesProcess.h"

@interface JPAckWindowController ()
- (void)loadAckTypes;
- (void)notePreferences;
- (void)updateHistoryWithTerm:(NSString*)term;
- (NSArray*)cleanseOptionList:(NSArray*)optionList;
- (NSString*)projectSelectedSearchFolder;
- (void)updateSearchSelectionForEvent:(NSEvent*)event;
@property(nonatomic, retain) JPAckProcess* currentProcess;
@property(nonatomic, retain) JPAckTypesProcess* currentTypesProcess;
@property(nonatomic, retain) NSArray* ackTypes;
@property(nonatomic, readwrite, copy) NSArray* history;
@property(nonatomic, copy) NSString* selectedSearchFolder;
@end

@implementation JPAckWindowController

NSString * const kJPAckLiteral = @"kJPAckLiteral";
NSString * const kJPAckNoCase = @"kJPAckNoCase";
NSString * const kJPAckMatchWords = @"kJPAckMatchWords";
NSString * const kJPAckShowContext = @"kJPAckShowContext";
NSString * const kJPAckFollowSymlinks = @"kJPAckFollowSymlinks";
NSString * const kJPAckFolderReferences = @"kJPAckFolderReferences";
NSString * const kJPAckSearchHistory = @"kJPAckSearchHistory";
NSString * const kJPAckSearchOptions = @"kJPAckSearchOptions";
NSString * const kJPAckWindowPosition = @"kJPAckWindowPosition";

@synthesize fileName;
@synthesize projectDirectory;
@synthesize selectedSearchFolder;
@synthesize ackTypes;
@synthesize history;
@synthesize term;
@synthesize nocase;
@synthesize literal;
@synthesize words;
@synthesize context;
@synthesize symlinks;
@synthesize folders;
@synthesize currentProcess;
@synthesize currentTypesProcess;

+ (NSSet*)keyPathsForValuesAffectingRunning
{
  return [NSSet setWithObject:@"currentProcess"];
}

+ (NSSet*)keyPathsForValuesAffectingWindowTitle
{
  return [NSSet setWithObject:@"fileName"];
}

+ (NSSet*)keyPathsForValuesAffectingSearchTitle
{
  return [NSSet setWithObject:@"selectedSearchFolder"];
}

+ (NSSet*)keyPathsForValuesAffectingCanSearch
{
  return [NSSet setWithObjects:@"selectedSearchFolder", @"running", @"term", nil];
}

- (id)initWithProjectDirectory:(NSString*)directory controller:(id)controller preferences:(NSMutableDictionary*)prefs
{
  if (self = [self initWithWindowNibName:@"JPAckWindow"])
  {
    history = nil;
    ackTypes = nil;
    term = nil;
    currentProcess = nil;
    currentTypesProcess = nil;

    projectController = controller;
    preferences = prefs;
    pasteboardChangeCount = NSNotFound;

    NSString* projectfile = [projectController filename] ? [projectController filename] : directory;
    fileName = [[[projectfile lastPathComponent] stringByDeletingPathExtension] copy];
    projectDirectory = [directory copy];
  }
  return self;
}

- (void)windowDidLoad
{
  [[self window] setContentBorderThickness:20.0 forEdge:NSMinYEdge];
  [optionsField setTokenizingCharacterSet:[NSCharacterSet whitespaceCharacterSet]];

  self.literal = [[preferences objectForKey:kJPAckLiteral] boolValue];
  self.nocase = [[preferences objectForKey:kJPAckNoCase] boolValue];
  self.words = [[preferences objectForKey:kJPAckMatchWords] boolValue];
  self.context = [[preferences objectForKey:kJPAckShowContext] boolValue];
  self.symlinks = [[preferences objectForKey:kJPAckFollowSymlinks] boolValue];
  self.folders = [[preferences objectForKey:kJPAckFolderReferences] boolValue];

  NSArray* savedHistory = [preferences objectForKey:kJPAckSearchHistory];
  self.history = (savedHistory) ? savedHistory : [NSArray array];

  NSArray* savedOptions = [preferences objectForKey:kJPAckSearchOptions];
  if (savedOptions)
    [optionsField setObjectValue:savedOptions];

  NSString* savedFrame = [preferences objectForKey:kJPAckWindowPosition];
  if (savedFrame)
    [[self window] setFrameFromString:savedFrame];
}

- (void)cleanupImmediately:(BOOL)immediately
{
  [self notePreferences];

  if (self.currentProcess)
    [self.currentProcess terminateImmediately:immediately];

  if (self.currentTypesProcess)
    [self.currentTypesProcess terminate];

  if (immediately)
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)windowShouldClose:(id)sender
{
  [self cleanupImmediately:NO];
  return YES;
}

- (void)notePreferences
{
  [preferences setObject:[NSNumber numberWithBool:self.literal] forKey:kJPAckLiteral];
  [preferences setObject:[NSNumber numberWithBool:self.nocase] forKey:kJPAckNoCase];
  [preferences setObject:[NSNumber numberWithBool:self.words] forKey:kJPAckMatchWords];
  [preferences setObject:[NSNumber numberWithBool:self.context] forKey:kJPAckShowContext];
  [preferences setObject:[NSNumber numberWithBool:self.symlinks] forKey:kJPAckFollowSymlinks];
  [preferences setObject:[NSNumber numberWithBool:self.folders] forKey:kJPAckFolderReferences];

  [preferences setObject:self.history forKey:kJPAckSearchHistory];
  [preferences setObject:[optionsField objectValue] forKey:kJPAckSearchOptions];
  [preferences setObject:[[self window] stringWithSavedFrame] forKey:kJPAckWindowPosition];
}

- (void)loadPasteboardTerm
{
  NSPasteboard *fbp = [NSPasteboard pasteboardWithName:NSFindPboard];
  if ([fbp changeCount] != pasteboardChangeCount && [fbp availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]])
  {
    pasteboardChangeCount = [fbp changeCount];
    self.term = [fbp stringForType:NSStringPboardType];
  }
}

- (void)savePasteboardTerm:(NSString*)term_
{
  if (!term_ || [term_ length] == 0)
    return;

  NSPasteboard *fbp = [NSPasteboard pasteboardWithName:NSFindPboard];

  // don't update the pasteboard if it's the same search term... it's *rude*
  if ([fbp availableTypeFromArray:[NSArray arrayWithObject:NSStringPboardType]] && [[fbp stringForType:NSStringPboardType] isEqualToString:term_])
    return;

  [fbp declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
  [fbp setString:term_ forType:NSStringPboardType];
  pasteboardChangeCount = [fbp changeCount];
}

- (void)showAndActivate
{
  [self loadPasteboardTerm];
  [self showWindow:nil];
  [self loadAckTypes];
  [[self window] makeFirstResponder:searchTermField];
}

- (IBAction)performSearch:(id)sender
{
  if (!term || ![term length])
    return;

  [self savePasteboardTerm:term];
  [self updateHistoryWithTerm:term];

  [self notePreferences];

  [ackResult clearContents];

  NSString* folderPattern = nil;
  if (folders)
    folderPattern = [[[NSUserDefaults standardUserDefaults] stringForKey:@"OakFolderReferenceFolderPattern"] substringFromIndex:1];

  self.currentProcess = [[[JPAckProcess alloc] initWithResultHolder:ackResult] autorelease];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentProcessCompleted:) name:JPAckProcessComplete object:self.currentProcess];
  NSString* path = self.projectDirectory;
  [self.currentProcess invokeWithTerm:term
      path:path
      searchFolder:selectedSearchFolder
      literal:literal
      nocase:nocase
      words:words
      context:context
      symlinks:symlinks
      folderPattern:folderPattern
      options:[optionsField objectValue]];
}

- (void)flagsChanged:(NSEvent*)event
{
  [self updateSearchSelectionForEvent:event];
}

- (NSString*)projectSelectedSearchFolder
{
  NSString* tmSelectedFile = [[projectController environmentVariables] objectForKey:@"TM_SELECTED_FILE"];

  if (!tmSelectedFile) return nil;

  BOOL isdir = NO;

  if ([[NSFileManager defaultManager] fileExistsAtPath:tmSelectedFile isDirectory:&isdir] && isdir)
    return tmSelectedFile;
  
  return nil;
}

- (void)windowDidResignMain:(NSNotification*)notification
{
  selectionSearch = NO;
  self.selectedSearchFolder = nil;
}

- (void)windowDidBecomeMain:(NSNotification*)notification
{
  [self updateSearchSelectionForEvent:[NSApp currentEvent]];
}

- (void)updateSearchSelectionForEvent:(NSEvent*)event
{
  selectionSearch = ([event modifierFlags] & NSCommandKeyMask) ? YES : NO;
  if (selectionSearch)
    self.selectedSearchFolder = [self projectSelectedSearchFolder];
  else
    self.selectedSearchFolder = nil;
}

- (NSString*)searchTitle
{
  return (selectionSearch) ? @"In Selection" : @"Search";
}

- (BOOL)canSearch
{
  if ([self running] || ![self term] || (selectionSearch && !self.selectedSearchFolder)) 
    return NO;

  return YES;
}

- (void)loadAckTypes
{
  if (self.currentTypesProcess)
    return;

  self.currentTypesProcess = [[[JPAckTypesProcess alloc] init] autorelease];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTypesProcessCompleted:) name:JPAckTypesProcessComplete object:self.currentTypesProcess];
  NSString* path = self.projectDirectory;
  [self.currentTypesProcess invokeWithPath:path options:[optionsField objectValue]];
}

- (void)openProjectFile:(NSString*)file atLine:(NSString*)line selectionRange:(NSRange)selectionRange
{
  NSString* absolute = [projectDirectory stringByAppendingPathComponent:file];
  [[[NSApplication sharedApplication] delegate] openFiles:[NSArray arrayWithObject:absolute]];

  for (NSWindow *w in [[NSApplication sharedApplication] orderedWindows])
  {
    id wc = [w windowController];
    NSString* openFileName = nil;

    if ([[wc className] isEqualToString:@"OakProjectController"] || [[wc className] isEqualToString:@"OakDocumentController"])
      openFileName = [[[wc textView] document] filename];

    if ([openFileName isEqualToString:absolute])
    {
      [[wc textView] goToLineNumber:line];
      [[wc textView] goToColumnNumber:[NSNumber numberWithInt:selectionRange.location + 1]];

      if (selectionRange.length > 0)
        [[wc textView] selectToLine:line andColumn:[NSNumber numberWithInt:selectionRange.location + selectionRange.length + 1]];

      break;
    }
  }
}

- (IBAction)cancel:(id)sender
{
  if ([self running])
    [self.currentProcess terminateImmediately:NO];
  else
    [[self window] performClose:nil];
}

- (void)updateHistoryWithTerm:(NSString*)term_
{
  NSMutableArray* newHistory = [[history mutableCopy] autorelease];
  [newHistory removeObject:term_];
  [newHistory insertObject:term_ atIndex:0];

  NSInteger ccount = [newHistory count];
  if (ccount > 10)
  {
    NSRange toRemove = NSMakeRange(10, (ccount - 10));
    [newHistory removeObjectsInRange:toRemove];
  }

  self.history = newHistory;
}

- (NSString*)windowTitle
{
  return [NSString stringWithFormat:@"AckMate: %@", fileName];
}

- (NSArray *)tokenField:(NSTokenField*)tokenField shouldAddObjects:(NSArray*)tokens atIndex:(NSUInteger)index
{
  return [self cleanseOptionList:tokens];
}

- (IBAction)cleanseOptionsField:(id)sender
{
  if (sender == optionsField)
    [sender setObjectValue:[self cleanseOptionList:[sender objectValue]]];
}

- (NSArray*)cleanseOptionList:(NSArray*)optionList
{
  NSMutableArray* okayOptions = [NSMutableArray array];
  for (NSString* option in optionList)
  {
    if ([option isEqualToString:@"--"] || [option isEqualToString:@"-"] || [option isEqualToString:@"--match"] || [option hasPrefix:@"--ackmate"])
      continue;

    if ([option hasPrefix:@"-"] || [ackTypes containsObject:option])
      [okayOptions addObject:option];
  }
  return okayOptions;
}

- (NSArray *)tokenField:(NSTokenField*)tokenField completionsForSubstring:(NSString*)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(NSInteger*)selectedIndex
{
  NSMutableArray* suggestions = [NSMutableArray array];
  if ([substring hasPrefix:@"-"])
    return suggestions;

  for (NSString* acktype in [self ackTypes])
  {
    if ([acktype hasPrefix:substring])
      [suggestions addObject:acktype];
  }

  *selectedIndex = 0;
  return suggestions;
}

- (void)currentProcessCompleted:(NSNotification*)notification
{
  if ([notification object] == self.currentProcess)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JPAckProcessComplete object:[notification object]];
    self.currentProcess = nil;
    [[self window] makeFirstResponder:searchTermField];
  }
}

- (void)currentTypesProcessCompleted:(NSNotification*)notification
{
  if ([notification object] == self.currentTypesProcess)
  {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:JPAckTypesProcessComplete object:[notification object]];
    self.currentTypesProcess = nil;
    NSMutableArray* tarr = [[[[notification userInfo] objectForKey:kJPAckTypesResult] mutableCopy] autorelease];
    if (tarr)
    {
      [tarr removeObject:@""]; // empty string because of final newline
      for (NSString* acktype in [[notification userInfo] objectForKey:kJPAckTypesResult])
      {
        if (![acktype isEqualToString:@""])
          [tarr addObject:[NSString stringWithFormat:@"no%@", acktype]];
      }

      self.ackTypes = tarr;
    }
  }
}

- (BOOL)running
{
  return (self.currentProcess) ? YES : NO;
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [fileName release], fileName = nil;
  [projectDirectory release], projectDirectory = nil;
  [selectedSearchFolder release], selectedSearchFolder = nil;
  [term release], term = nil;
  [ackTypes release], ackTypes = nil;
  [history release], history = nil;
  [currentProcess release], currentProcess = nil;
  [currentTypesProcess release], currentTypesProcess = nil;
  [super dealloc];
}
@end
