// Copyright (c) 2010 Trevor Squires. All Rights Reserved.
// See License.txt for full license.

#import "JPAckProcess+Parsing.h"
#import "JPAckResultSource.h"

#define NSUTF8STRING(pFirstChar, pLastChar) [[[NSString alloc] initWithBytes:pFirstChar length:(pLastChar - pFirstChar) encoding:NSUTF8StringEncoding] autorelease]

@interface JPAckProcess (ParsingPrivate)
- (void)extractResult:(char*)line length:(NSUInteger)length;
@end

@implementation JPAckProcess (Parsing)

%%{
  machine lineconsumer;
  LF = '\n';

  action mark { mark = fpc; }
  action process_line { [self extractResult:mark length:(fpc - mark)]; }
  action partial_line { [self saveTrailing:mark length:(fpc - mark)]; }

  input_line = ( any -- LF )** >mark LF;
  InputLines = (input_line %process_line)+ @!partial_line;

  main := InputLines;
}%%

%% write data;

- (void)consumeInputLines:(NSData*)data
{
  NSUInteger length = [data length];
  char* bytes = (char*)[data bytes];

  char *p = bytes;
  char *pe = bytes + length;
  char *eof = pe;
  char *mark = NULL;
  int cs;

  %% write init;
  %% write exec;
}

%%{
  # this machine gets lines in the following form:
  # :some/FileName.whateverESC[0m
  # 23: some context text
  # 24:     more context text
  # 25;1 4,5 4: A matching Line we are interested in has ; and optional ranges
  # 26: more context text
  # --
  # 35:
  # 36;2 1: another Line
  # :another/FileNameMaybeWithBogusEscapes.whatever
  # 1;: Just one Line and there's no ranges

  machine resultextractor;

  LF = "\n";

  action mark { mark = fpc; }

  action save_line_number {
    currentLineNumber = NSUTF8STRING(mark, p);
  }

  action save_context_break {
    [ackResult parsedContextBreak];
  }

  action save_filename_content {
    [ackResult parsedFilename:NSUTF8STRING(mark, p)];
  }

  action save_context_content {
    [ackResult parsedContextLine:currentLineNumber content:NSUTF8STRING(mark, p)];
  }

  action save_match_content {
    [ackResult parsedMatchLine:currentLineNumber ranges:currentRanges content:NSUTF8STRING(mark, p)];
  }

  action save_range_content {
    if (!currentRanges)
      currentRanges = [NSMutableArray array];

    [currentRanges addObject:NSUTF8STRING(mark, p)];
  }

  filename_content = (any -- LF)** >mark %save_filename_content;
  line_number = digit+ >mark %save_line_number;
  context_content = (any -- LF)** >mark %save_context_content;
  match_content = (any -- LF)** >mark %save_match_content;
  range_content = (digit+ >mark " " digit+) %save_range_content;

  FilenameResult = ":" filename_content LF;
  ContextResult = line_number ":" context_content LF;
  MatchResult = line_number ";" (range_content (',')?)** ":" match_content LF;
  ContextBreak = ("--" . LF) %save_context_break;

  main := |*
    FilenameResult;
    ContextResult;
    ContextBreak;
    MatchResult;
  *|;
}%%

%% write data;

- (void)extractResult:(char*)bytes length:(NSUInteger)length
{
  NSString* currentLineNumber = nil;
  NSMutableArray* currentRanges = nil;

  char *p = bytes;
  char *pe = bytes + length;
  char* ts;
  char* te;
  int act;
  char *eof = pe;
  char *mark = NULL;
  int cs;

  %% write init;
  %% write exec;
}

@end

