//
//  NSScanner+Convenience.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSScanner (Convenience)


-(NSString*)remainder;
    // returns the remainder of the scanner string from the scanlocation to the end of the string.

-(unichar)currentCharacter;
    // returns the unichar at the current scanlocation.  if current scanlocation is after end of string, returns '\0'

-(unichar)characterAtOffset:(NSInteger)offset;
    // returns the unichar at the positive or negative offset from the current scan location.
    // if the offset location is <0 or greater than the strings length, returns '\0'

-(NSUInteger)advance:(NSUInteger)characterCount;
    // advances the scan location by amount.   if new scan location > end of scan string, sets scan location to be end of string.
    // returns the actual amount the location has moved (Should be same as argument if end of string is not reached.)
    // return values will be 0 if scan location is currently at end of scan string.


-(NSUInteger)rewind:(NSUInteger)characterCount;
    // rewinds the scan location by amount.   if new scan location < beginning of scan string, sets scan location to be beginning of string.
    // returns the actual amount the location has moved (Should be same as argument if beginning of string is not reached.)
    // return values will be 0 if scan location is currently at beginning of scan string.

-(BOOL)scanStringOfSize:(NSInteger)size intoString:(NSString**)outString;
-(BOOL)scanWhiteSpace;
-(BOOL)scanStringFromArray:(NSArray /*<NSString*>*/ *)strings intoString:(NSString**)outstring;
@end
