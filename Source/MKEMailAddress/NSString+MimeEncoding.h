//
//  NSString+MimeEncoding.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MimeEncoding)


/* Method +mimeWordWithString:preferredEncoding:encodingUsed:
 
    Returns a full mimeword encoded string for the provided string using the preferred encoding if possible
        If the provided string cannot be encoded with the preferred, it will use alternate encodings and return encoding used
        in the reference parameter.
 
    eg [NSString mimeWordWithString:@"Garçon" preferredEncoding:NSISOLatin1StringEncoding encodingUsed:0]
            returns @"=?iso-8859-1?Q?Gar=E7on?="
 
       [NSString mimeWordWithString:@"Garçon" preferredEncoding:NSUTF8StringEncoding encodingUsed:0]
            returns @"=?utf-8?Q?Gar=C3=A7on?="

 */

+ (NSString*) mimeWordWithString:(NSString*) string preferredEncoding:(NSStringEncoding)encoding encodingUsed:(NSStringEncoding*)usedEncoding;



/* Method +quotedPrintableStringWithString:preferredEncoding:encodingUsed:
    returns the quotedPrintableStringWithout the Mime Type Envelope.
 
   eg [NSString quotedPrintableStringWithString:@"Garçon" preferredEncoding:NSISOLatin1StringEncoding encodingUsed:0] 
        returns @"Gar=E7on"
 
    This should not be used for actual mime words but is provided so that methods can break the quotedPrintable at set length
    for headers or other purposes.
 
    NOTE -- in contravention of the RFC for QuotedPrintableStrings, the return value is not wrapped at 75 characters.  
            Wrapping is to be performed by client method.
*/


+ (NSString*) quotedPrintableStringWithString:(NSString *)string preferredEncoding:(NSStringEncoding)preferredEncoding encodingUsed:(NSStringEncoding *)usedEncoding;
+ (NSString*)quotedPrintableStringForPlainTextBody:(NSString *)string preferredEncoding:(NSStringEncoding)preferredEncoding encodingUsed:(NSStringEncoding *)usedEncoding;

+ (NSString*) MKcharSetNameForEncoding:(NSStringEncoding)encoding;
+ (NSStringEncoding) MKencodingForCharSetName:(NSString*)charSet;

+ (NSString*) stringWithMimeEncodedWord:(NSString*)word;
- (NSString*) decodedMimeEncodedString;

@end

