//
//  NSScanner+RFC2822.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EmailParserErrorCodes){
    kEmailParserUnclosedCommentError = 1,
    kEmailParserUnclosedAngularError = 2,
    kEmailParserUnclosedQuoteError = 3,
    kEmailParserMalformedAddrSpecError = 4,
    kEmailParserMalformedMimeDataError = 5,
    kEmailParserMalformedGroupError = 6,
    kEmailParserMalformedExtraneousTextAfterEmailError= 7,
    kEmailParserMalformedAddressNotEnclosedInAngularError=8
};

// Uncomment the following define to enforce strict RFC2822 compliance of email addresses
//      this may result in many real world addresses in email headers to not parse properly because general lack of RFC2822 compliance

//#define STRICT_RFC2822_COMPLIANCE

// DEBUG
// Uncomment the following define to have the scanner log out debug information when scanning
//
//#define DEBUG_RFC2822_SCANNER


@interface NSScanner (RFC2822)
// all method return true and advances if valid form is found.
// if there is an error argument: if an error is found, the reference arguments should be zero'd, the error argument filled (if non-nil reference), and the scan location unchanged.

-(BOOL) scanCRLF;
    // scans for CRLF at scan location.
    // return true and advances if found.  return false if not found.

-(BOOL) scanFoldingWhiteSpace;
    // Scans for a folding whitespace.

-(BOOL) scanCommentFoldingWhiteSpace;
    //  Scans for combination of comments (ctext) and folding whitespace.

-(BOOL) scanQuotedPairIntoString:(NSString**) returnString;
    // scans quoted pair (\x where x is any rfcTextSet character) into the returnString

-(BOOL) scanWordIntoString: (NSString**)returnString;
    // scans a valid Word
    // ABNF: word            =       atom / quoted-string


-(BOOL) scanPhraseIntoString: (NSString**)returnString;
    /* Augmented Backus-Naur Form:
     */


-(BOOL) scanAtomIntoString: (NSString**)returnString;
    /* Augmented Backus-Naur Form:
     */

-(BOOL) scanDotAtomIntoString: (NSString**)returnString;
    /* Augmented Backus-Naur Form:
     */


-(BOOL) scanQuotedStringIntoString: (NSString**) returnString
                             error: (NSError**) error;
    // scans the contents (excluding opening and closing quote character) of the quotedString into return string
    // scan string must have opening quote at current scan location when called.
    // if scanner encounters an illegal character or end of scan string before reaching closing quote
    //      scanner resets scan location to beginning start location
    //      and returns NO, with kEmailParserUnclosedQuoteError in error argument.

    /* Augmented Backus-Naur Form:
     *
     *  qtext           =        NO-WS-CTL /     ; Non white space controls
     *                           %d33 /          ; The rest of the US-ASCII
     *                           %d35-91 /       ;  characters not including "\"
     *                           %d93-126        ;  or the quote character
     *
     *  qcontent        =       qtext / quoted-pair
     *
     *  quoted-string   =       [CFWS]
     *                           DQUOTE *([FWS] qcontent) [FWS] DQUOTE
     *                          [CFWS]
     */

-(BOOL) scanCommentIntoString:(NSString**) returnString
                        error:(NSError**) error;

-(BOOL) scanLocalPartIntoString:(NSString**) returnString;

-(BOOL) scanDomainIntoString:(NSString**) returnString;

-(BOOL) scanAngularAddrSpecIntoLocalName:(NSString**) localNameString
                                  domain:(NSString**) domainString
                                   error:(NSError**) error;

-(BOOL) scanAddrSpecIntoLocalName:(NSString**) localNameString
                           domain:(NSString**) domainString
                            error:(NSError**) error;

-(BOOL) scanMimeEncodedWordIntoString:(NSString**) returnString
                                error:(NSError**) error;

-(BOOL) scanGroupIntoGroupName:(NSString**) returnNameString
                     addresses:(NSString**) addressesString
                         error:(NSError**) error;

-(BOOL) scanRFC2822EmailAddressIntoDisplayName:(NSString**) displayName
                                     localName:(NSString**) localName
                                        domain:(NSString**) domain
                                         error:(NSError**) error;

@end
