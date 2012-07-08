// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import <Cocoa/Cocoa.h>

@class JPAckResultSource;
@class JPAckProcess;
@class JPAckTypesProcess;

extern NSString * const kJPAckLiteral;
extern NSString * const kJPAckShowAdvanced;
extern NSString * const kJPAckNoCase;
extern NSString * const kJPAckMatchWords;
extern NSString * const kJPAckShowContext;
extern NSString * const kJPAckFollowSymlinks;
extern NSString * const kJPAckFolderReferences;
extern NSString * const kJPAckSearchHistory;
extern NSString * const kJPAckSearchOptions;
extern NSString * const kJPAckWindowPosition;

@interface JPAckWindowController : NSWindowController {
  IBOutlet JPAckResultSource* ackResult;
  IBOutlet NSTokenField* optionsField;
  IBOutlet NSComboBox* searchTermField;
  IBOutlet NSButton* showContextButton;
  IBOutlet NSButton* followSymlinksButton;
  IBOutlet NSButton* useFolderReferencesButton;
  IBOutlet NSButton* advancedDisclosure;
  IBOutlet NSButton* advancedButton;
  IBOutlet NSBox* optionsBox;
  IBOutlet NSView* controlView;
  IBOutlet NSScrollView* resultsView;

  NSInteger pasteboardChangeCount;
  NSString* projectDirectory;
  NSString* selectedSearchFolder;
  BOOL      selectionSearch;
  NSString* fileName;
  NSTask*   mateTask;

  NSMutableDictionary* preferences;
  NSArray* history;
  NSArray* ackTypes;

  NSString* term;
  BOOL showAdvanced;
  BOOL nocase;
  BOOL literal;
  BOOL words;
  BOOL context;
  BOOL symlinks;
  BOOL folders;
  id projectController;
  JPAckProcess* currentProcess;
  JPAckTypesProcess* currentTypesProcess;
}
@property(nonatomic, readonly, copy) NSString* projectDirectory;
@property(nonatomic, readonly, copy) NSString* fileName;
@property(nonatomic, readonly, copy) NSArray* history;
@property(nonatomic, copy) NSString* term;
@property(nonatomic, assign) BOOL showAdvanced;
@property(nonatomic, assign) BOOL nocase;
@property(nonatomic, assign) BOOL literal;
@property(nonatomic, assign) BOOL words;
@property(nonatomic, assign) BOOL context;
@property(nonatomic, assign) BOOL symlinks;
@property(nonatomic, assign) BOOL folders;

- (id)initWithProjectDirectory:(NSString*)directory controller:(id)controller preferences:(NSMutableDictionary*)prefs;
- (void)showAndActivate;
- (IBAction)cleanseOptionsField:(id)sender;
- (void)openProjectFile:(NSString*)file atLine:(NSString*)line selectionRange:(NSRange)selectionRange;
- (IBAction)performSearch:(id)sender;
- (IBAction)cancel:(id)sender;
- (BOOL)running;
- (NSString*)windowTitle;
- (void)cleanupImmediately:(BOOL)immediately;
@end

@interface NSObject (AckMateCompilerSilencing)
- (void)openFiles:(id)farray;
- (void)goToLineNumber:(id)line;
- (void)goToColumnNumber:(id)col;
- (void)selectToLine:(id)line andColumn:(id)col;
- (id)environmentVariables;
- (id)document;
@end