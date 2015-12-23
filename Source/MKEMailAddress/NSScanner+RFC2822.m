//
//  NSScanner+RFC2822.m
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NSScanner+RFC2822.h"

#import "NSScanner+Convenience.h"
#import "NSCharacterSet+RFC2822Sets.h"
#import "NSString+MimeEncoding.h"


@implementation NSScanner (RFC2822)
-(BOOL)scanCRLF{
    if ([self scanLocation]>=[self.string length]-1){
        return NO;
    }
    if ([[self.string substringWithRange:NSMakeRange(self.scanLocation, 2)] isEqualToString:@"\r\n"]){
        [self advance:2];
        return YES;
    }
    if ([[self.string substringWithRange:NSMakeRange(self.scanLocation, 1)] isEqualToString:@"\n"]){
        [self advance:1];
        return YES;
    }
    
    return NO;
}



-(BOOL)scanFoldingWhiteSpace{
    //([*WSP CRLF] 1*WSP)
    NSUInteger startLocation = self.scanLocation;
    
    [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
    [self scanCRLF];
    [self scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:nil];
    return self.scanLocation>startLocation;
}
-(BOOL)scanCommentFoldingWhiteSpace{
    NSUInteger startLocation = self.scanLocation;
    NSInteger lastLocation = -1;
    while ([self scanFoldingWhiteSpace] ||
           [self scanRFC2822CommentIntoString:nil error:nil]){
        // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
        if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
            // clear the reference parameters if they have been set
            return NO;
        }
        lastLocation = (NSInteger)self.scanLocation;
        
        if ([self isAtEnd]){
            break;
        }
        
    }
    return self.scanLocation>startLocation;
}

-(BOOL)scanQuotedPairIntoString:(NSString**)returnString{
    
    NSCharacterSet * textCS = [NSCharacterSet rfc2822TextSet];
    
    NSUInteger startLocation = self.scanLocation;
    if ([self currentCharacter]=='\\'){  // single backslash
        unichar followingCharacter =[self characterAtOffset:1];
        if ([textCS characterIsMember:followingCharacter]){
            if (returnString){
                *returnString = [NSString stringWithFormat:@"%c",followingCharacter];
            }
            [self advance:2];
        }
    }
    return self.scanLocation>startLocation;
}

-(BOOL)scanWordIntoString:(NSString**)returnString{
   NSUInteger  startLocation = self.scanLocation;
    [self scanCommentFoldingWhiteSpace];
    if ([self currentCharacter]=='"'){
        NSString * quotedString = nil;
        [self scanQuotedStringIntoString:&quotedString error:nil];
        if (quotedString && returnString){
            *returnString = [NSString stringWithFormat:@"\"%@\"",quotedString];
        }
    }
    else{
        [self scanAtomIntoString:returnString];
    }
    return self.scanLocation>startLocation;
}

-(BOOL)scanPhraseIntoString:(NSString**) returnString{
    NSUInteger startLocation = self.scanLocation;
    NSMutableString * mstr = [NSMutableString string];
    NSString * scannedString = nil;
    NSInteger lastLocation = -1;
    while([self scanWordIntoString:&scannedString]){
        // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
        if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
            // clear the reference parameters if they have been set
            return NO;
        }
        lastLocation = (NSInteger)self.scanLocation;

        if (scannedString){
            [mstr appendString:scannedString];
            BOOL hasAddedSpace = NO;
            if ([self scanFoldingWhiteSpace]){
                [mstr appendString:@" "];
                hasAddedSpace= YES;
            }
            NSInteger lastLocation = -1;
            while([self scanRFC2822CommentIntoString:nil error:nil]){
                // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
                if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
                    // clear the reference parameters if they have been set
                    self.scanLocation = startLocation;
                    return NO;
                }
                lastLocation = (NSInteger)self.scanLocation;

                if ([self scanFoldingWhiteSpace] && !hasAddedSpace){
                    [mstr appendString:@" "];
                    hasAddedSpace = YES;
                    
                }
            }
        }
        // obsoleted phrase allows '.' after first word
        if ([self currentCharacter]=='.'){
            [mstr appendString:@"."];
            [self advance:1];
            BOOL hasAddedSpace = NO;
            if ([self scanFoldingWhiteSpace]){
                [mstr appendString:@" "];
                hasAddedSpace= YES;
            }
            NSInteger lastLocation = -1;
            while([self scanRFC2822CommentIntoString:nil error:nil]){
                // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
                if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
                    // clear the reference parameters if they have been set
                    self.scanLocation = startLocation;
                    return NO;
                }
                lastLocation = (NSInteger)self.scanLocation;
                if ([self scanFoldingWhiteSpace] && !hasAddedSpace){
                    [mstr appendString:@" "];
                    hasAddedSpace = YES;
                    
                }
            }
        }
        
        if ([self isAtEnd]){
            break;
        }
    }
    if (returnString){
        *returnString = [mstr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    return self.scanLocation>startLocation;
}

-(BOOL)scanAtomIntoString:(NSString**)returnString{
    NSUInteger startLocation = self.scanLocation;
    [self scanFoldingWhiteSpace];
    [self scanCharactersFromSet:[NSCharacterSet rfc2822atomTextSet] intoString:returnString];
    //[self scanFoldingWhiteSpace];
    return self.scanLocation>startLocation;
}

-(BOOL)scanDotAtomIntoString:(NSString**)returnString{
    
    NSUInteger startLocation = self.scanLocation;
    [self scanCommentFoldingWhiteSpace];
    NSString * scannedString1 = nil;
    NSString * scannedString2 = nil;
    [self scanCharactersFromSet:[NSCharacterSet rfc2822atomTextSet] intoString:returnString?&scannedString1:0];
    [self scanCharactersFromSet:[NSCharacterSet rfc2822dotAtomTextSet] intoString:returnString?&scannedString2:0];
    if (returnString && scannedString1 && scannedString2){
        *returnString = [scannedString1 stringByAppendingString:scannedString2];
    }
    else if (returnString && scannedString1){
        *returnString = scannedString1;
    }
    [self scanCommentFoldingWhiteSpace];
    return self.scanLocation>startLocation;
}

-(BOOL) scanQuotedStringIntoString:(NSString**)returnString error:(NSError**)error{
    
    if ([self currentCharacter]!='"'){
        return NO;
    }
    NSUInteger startLocation = self.scanLocation;
    
    if (![self advance:1]){
        if (error){
            *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserUnclosedQuoteError userInfo:@{NSLocalizedDescriptionKey:@"QuotedString was not closed"}];
        }
        else{
            NSAssert(YES,@"QuotedString was not closed");
        }
        self.scanLocation = startLocation;
        return NO;
    }
    
    
    BOOL quoteClosed = NO;
    NSMutableString * quotedText = [NSMutableString string];
    NSInteger lastLocation = -1;
    while(![self isAtEnd]){
        // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
        if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
            // clear the reference parameters if they have been set
            if (error){
                *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserIllegalCharacterError userInfo:@{NSLocalizedDescriptionKey:@"QuotedString included non ASCII character"}];
                self.scanLocation = startLocation;
                return NO;
            }
            else{
                NSAssert(YES,@"QuotedString was not closed");
            }
            return NO;
        }
        lastLocation = (NSInteger)self.scanLocation;
        
        NSString * scannedText = nil;
        
        if ([self scanCharactersFromSet:[NSCharacterSet rfc2822ExtendedQTextSet] intoString:&scannedText]){
            if ([scannedText canBeConvertedToEncoding:NSASCIIStringEncoding]){
                [quotedText appendString:scannedText];
            }
            else {
                // text contains characters > 127.    So we do some guessing as to what it may be ---
                // this may be incorrect but chance are the email sender didn't mime encode things so
                // we are left with trying to gues what encoding they used.
                
                static CFStringEncoding preferredEncodings[] = {
                    kCFStringEncodingASCII,
                    kCFStringEncodingISOLatin1,
                    kCFStringEncodingISOLatin2,
                    // no constants available for ISO8859-3 through ISO8859-15
                    kCFStringEncodingISOLatin3,
                    kCFStringEncodingISOLatin4,
                    kCFStringEncodingISOLatinCyrillic,
                    kCFStringEncodingISOLatinArabic,
                    kCFStringEncodingISOLatinGreek,
                    kCFStringEncodingISOLatinHebrew,
                    kCFStringEncodingISOLatin5,
                    kCFStringEncodingISOLatin6,
                    kCFStringEncodingISOLatinThai,
                    kCFStringEncodingISOLatin7,
                    kCFStringEncodingISOLatin8,
                    kCFStringEncodingISOLatin9,
                    kCFStringEncodingUTF8,
                    0 };
                
                NSStringEncoding stringEncoding = 0;
                NSData * encodedData = nil;
                
                CFStringEncoding *encodingPtr;
                for(encodingPtr = preferredEncodings; *encodingPtr != 0; encodingPtr++)
                {
                    stringEncoding = CFStringConvertEncodingToNSStringEncoding(*encodingPtr);
                    if([scannedText canBeConvertedToEncoding:stringEncoding])
                    {
                        encodedData = [scannedText dataUsingEncoding:stringEncoding];
                        break;
                    }
                }
                
                if (encodedData){
                    NSString * convertedString =  [[NSString alloc] initWithData:encodedData encoding:stringEncoding];
                    [quotedText appendString:convertedString];
                }
            }
        }
        if ([self currentCharacter]=='"'){
            quoteClosed = YES;
            [self advance:1];
            break;
        }
        if ([self scanQuotedPairIntoString:&scannedText]){
            [quotedText appendString:scannedText];
        }
    }
    if (!quoteClosed){
        if (error){
            *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserUnclosedQuoteError userInfo:@{NSLocalizedDescriptionKey:@"QuotedString was not closed"}];
            self.scanLocation = startLocation;
            return NO;
        }
        else{
            NSAssert(YES,@"QuotedString was not closed");
        }
    }
    if (returnString){
        *returnString = quotedText;
    }
    return self.scanLocation>startLocation;
}


-(BOOL) scanRFC2822CommentIntoString:(NSString**)returnString error:(NSError**)error{
    
    
    NSUInteger startLocation = self.scanLocation;
    
    if ([self currentCharacter]!='('){
        return NO;
    }
    
    if (![self advance:1]){
        self.scanLocation = startLocation;
        return NO;
    }
    NSMutableString * comment = [NSMutableString string];
    BOOL closedParenthesis = NO;
    NSInteger lastLocation = -1;
    while(![self isAtEnd]){
        // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
        if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
            // clear the reference parameters if they have been set
            self.scanLocation = startLocation;
            return NO;
        }
        lastLocation = (NSInteger)self.scanLocation;
        
        if ([self scanFoldingWhiteSpace]){
            [comment appendString:@" "];
            continue;
        }
        NSString * scannedText = nil;
        if ([self scanCharactersFromSet:[NSCharacterSet rfc2822CTextSet] intoString:&scannedText]){
            if (scannedText) [comment appendString:scannedText];
            continue;
        }
        NSString * quotedPair = nil;
        if ([self scanQuotedPairIntoString:&quotedPair]){
            if (quotedPair) [comment appendString:quotedPair];
            continue;
        }
        if ([self currentCharacter]=='('){
            NSString * nestedComment = nil;
            [self scanRFC2822CommentIntoString:&nestedComment error:nil];
            if (nestedComment) [comment appendFormat:@"(%@)",nestedComment];
            continue;
        }
        if ([self currentCharacter]==')'){
            closedParenthesis = YES;
            [self advance:1];
            break;
        }
    }
    if (!closedParenthesis){
        if (error){
            *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserUnclosedCommentError userInfo:@{NSLocalizedDescriptionKey:@"Comment was not closed"}];
        }
        else{
            NSAssert(YES,@"Comment was not closed");
        }
        self.scanLocation = startLocation;
        return NO;
    }
    if (self.scanLocation>startLocation && returnString){
        *returnString = comment;
    }
    
    return self.scanLocation>startLocation;
}


-(BOOL)scanLocalPartIntoString:(NSString**)returnString{
    NSUInteger startLocation = self.scanLocation;
    if (![self scanDotAtomIntoString:returnString]){
        NSString * quotedString = nil;
        if ( [self scanQuotedStringIntoString:&quotedString error:nil]){
            if (quotedString && returnString){
                *returnString = [NSString stringWithFormat:@"\"%@\"",quotedString];
            }
        }
        
    }
    return self.scanLocation>startLocation;
}

-(BOOL)scanDomainIntoString:(NSString**)returnString{
    NSUInteger startLocation = self.scanLocation;
    [self scanDotAtomIntoString:returnString];
    return self.scanLocation>startLocation;
}
- (BOOL)scanAngularAddrSpecIntoLocalName:(NSString**)localNameString domain:(NSString**) domainString error:(NSError**)error{
    if ([self currentCharacter]!='<'){
        return NO;
    }
    NSUInteger startLocation = self.scanLocation;
    
    if (![self advance:1]){
        if (error){
            *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserUnclosedAngularError userInfo:@{NSLocalizedDescriptionKey:@"Unclosed Angular Bracket Error"}];
        }
        else{
            NSAssert(YES,@"Unclosed Angular Bracket Error");
        }
        self.scanLocation = startLocation;
        return NO;
        
    }
    
    BOOL closeAngular = NO;
    NSInteger lastLocation = -1;
    while(![self isAtEnd]){
        // prevent an infinite loop by checking that the scanLocation is moving forward on each loop
        if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
            // clear the reference parameters if they have been set
            self.scanLocation = startLocation;
            return NO;
        }
        lastLocation = (NSInteger)self.scanLocation;
        
        NSError * addrSpecError = nil;
        if ([self scanAddrSpecIntoLocalName:localNameString domain:domainString error:&addrSpecError]){
            
        }
        if (addrSpecError){
            if (error) *error = addrSpecError;
            self.scanLocation = startLocation;
            return NO;
        }
        if ([self currentCharacter]=='>'){
            closeAngular = YES;
            [self advance:1];
            break;
        }
    }
    if (!closeAngular){
        self.scanLocation = startLocation;
        if (error){
            *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserUnclosedAngularError userInfo:@{NSLocalizedDescriptionKey:@"Unclosed Angular Bracket Error"}];
        }
        else{
            NSAssert(YES,@"Unclosed Angular Bracket Error");
        }
        return NO;
    }
    return self.scanLocation>startLocation;
}
- (BOOL)scanAddrSpecIntoLocalName:(NSString**)localNameString domain:(NSString**) domainString error:(NSError**)error{
    NSUInteger startLocation = self.scanLocation;
    if ([self scanLocalPartIntoString:localNameString]){
        if ([self currentCharacter]=='@'){
            [self advance:1];
            if (![self scanDomainIntoString:domainString]){
                if (localNameString) *localNameString=nil;
                if (error){
                    *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedAddrSpecError userInfo:@{NSLocalizedDescriptionKey:@"Malformed Email Address Spec"}];
                }
                else{
                    NSAssert(YES,@"Malformed Email Address Spec");
                }
                self.scanLocation = startLocation;
                return NO;
            }
        }
        else{
            if (localNameString) *localNameString=nil;
            
            if (error){
                *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedAddrSpecError userInfo:@{NSLocalizedDescriptionKey:@"Malformed Email Address Spec"}];
            }
            else{
                NSAssert(YES,@"Malformed Email Address Spec");
            }
            self.scanLocation = startLocation;
            return NO;
        }
        
    }
    return self.scanLocation>startLocation;
}
-(BOOL)scanMimeEncodedWordIntoString:(NSString**)returnString error:(NSError**)error{
    NSUInteger startLocation = self.scanLocation;
    if ([self characterAtOffset:1]=='?'){
        [self advance:2];
        NSString * encoding = nil;
        [self scanUpToString:@"?" intoString:&encoding];
        [self advance:1];
        NSString * format = nil;
        [self scanUpToString:@"?" intoString:&format];
        format = [format uppercaseString];
        if (![format isEqualToString:@"Q"] && ![format isEqualToString:@"B"]){
            if (error){
                *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedMimeDataError userInfo:@{NSLocalizedDescriptionKey:@"Malformed Mime Data"}];
            }
            else{
                NSAssert(YES,@"Malformed Email Address Spec");
            }
            self.scanLocation = startLocation;
            return NO;
        }
        [self advance:1];
        [self scanUpToString:@"?=" intoString:nil];
        if ([self scanString:@"?=" intoString:nil]){
            if (returnString){
                *returnString =[self.string substringWithRange:NSMakeRange(startLocation, self.scanLocation-startLocation)];
            }
        }
        else{
            if (error){
                *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedMimeDataError userInfo:@{NSLocalizedDescriptionKey:@"Malformed Mime Data"}];
            }
            else{
                NSAssert(YES,@"Malformed Email Address Spec");
            }
            
            self.scanLocation = startLocation;
        }
    }
    
    
    return self.scanLocation>startLocation;
}
-(BOOL)scanGroupIntoGroupName:(NSString**)returnNameString addresses:(NSString**)addressesString error:(NSError**)error{
    NSUInteger startLocation = self.scanLocation;
    NSString * phrase = nil;
    if ([self scanPhraseIntoString:&phrase]){
        if ([self currentCharacter]==':'){
            [self advance:1];
            if (returnNameString) *returnNameString = phrase;
            [self scanUpToString:@";" intoString:addressesString];
            if([self isAtEnd]){
                if (error){
                    *error = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedGroupError userInfo:@{NSLocalizedDescriptionKey:@"Malformed Group Data"}];
                }
                else{
                    NSAssert(YES,@"Malformed Email Address Spec");
                }
                self.scanLocation= startLocation;
                return NO;
            }
            else{
                [self advance:1];
            }
        }
        else{
            // no ':',  so not a group so rewind
            self.scanLocation=startLocation;
        }
        
    }
    
    return self.scanLocation>startLocation;
}

-(BOOL)scanRFC2822EmailAddressIntoDisplayName:(NSString**) displayName localName:(NSString**) localName domain:(NSString**)domain error:(NSError**)error{
    [self setCharactersToBeSkipped:nil];
    if (displayName) *displayName= nil;
    if (localName) *localName= nil;
    if (domain) *domain= nil;
    if (error) *error= nil;
    
    NSUInteger startLocation = self.scanLocation;
    NSError * internalError = nil;
    BOOL foundDelimiter = NO;
    BOOL previousWordWasMimeEncoded = NO;
    NSInteger lastLocation = -1;
    while(![self isAtEnd] && !internalError && !foundDelimiter){
        
        // each pass of the scan loop should advance the scan location.
        // if this doesn't happen, it means that there is something creating a loop.   and this is bad.
        if ((NSInteger)self.scanLocation <= (NSInteger)lastLocation){
            // clear the reference parameters if they have been set
            if (displayName) *displayName= nil;
            if (localName) *localName= nil;
            if (domain) *domain= nil;
            if (error) {
                *error= [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserCannotParseError userInfo:@{NSLocalizedDescriptionKey:@"Parser found it self in a loop while parsing email"}];
            }
            return NO;
        }
        lastLocation = (NSInteger)self.scanLocation;
        
        [self scanFoldingWhiteSpace];
        if ((localName && domain && !*localName && !*domain)&& [self scanAddrSpecIntoLocalName:localName domain:domain error:nil]){
#ifdef DEBUG_RFC2822_SCANNER
            if (localName && domain){
                NSLog (@"EmailAddress: %@@%@",*localName,*domain);
            }
#endif
            [self scanCommentFoldingWhiteSpace];
            if (![self isAtEnd] && [self currentCharacter]!=',' ){
                if ([self currentCharacter] == '<'){
                    if (localName && domain){
                        if (displayName) *displayName = [NSString stringWithFormat:@"%@@%@",*localName,*domain];
                    }
                    [self scanAngularAddrSpecIntoLocalName:localName domain:domain error:&internalError];
                    continue;
                }
                else{
                    internalError = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedExtraneousTextAfterEmailError userInfo:@{NSLocalizedDescriptionKey:@"Found email address has extraneous text following valid address"}];
                }
            }
            continue;
        }
        unichar nextChar = [self currentCharacter];
        switch(nextChar){
            case 32:
            case 9:
            {
                [self advance:1];
                break;
            }
            case '@':{
                // it should not run into a @ if it already has scanned an email  so this is an error
                internalError = [NSError errorWithDomain:@"ca.indev.emailParser" code:kEmailParserMalformedAddressNotEnclosedInAngularError userInfo:@{NSLocalizedDescriptionKey:@"Found @ unenclosed in angular brackets when display name found"}];
                continue;
            }
            case '=':{
                NSString * mimeData = nil;
                if ([self scanMimeEncodedWordIntoString:&mimeData error:&internalError]){
                    if (mimeData){
#ifdef DEBUG_RFC2822_SCANNER
                        NSLog (@"EncodedString: %@ --> %@",mimeData,[NSString stringWithMimeEncodedWord:mimeData]);
#endif
                    }
                    if (displayName) {
                        NSString * decodedWord = [NSString stringWithMimeEncodedWord:mimeData];
                        if  (*displayName ){
                            if (previousWordWasMimeEncoded){
                                // string together mime encoded words with no space
                                *displayName = [NSString stringWithFormat:@"%@%@",*displayName,decodedWord];
                            }
                        }else{
                            *displayName =decodedWord;
                        }
                    }

                    previousWordWasMimeEncoded = YES;
                    break;
                }
                // no break if scanner doesn't advance
            }
            case '(':{
                NSString * comment = nil;
                
                [self scanRFC2822CommentIntoString:&comment error:&internalError];
#ifdef DEBUG_RFC2822_SCANNER
                NSLog (@"comment: %@",comment);
#endif
                break;
            }
            case '"':{
                // scan a quoted String
                NSString * quotedText = nil;
                
                if ([self scanQuotedStringIntoString:&quotedText error:&internalError]){
#ifdef DEBUG_RFC2822_SCANNER
                    NSLog (@"quotedText: %@",quotedText);
#endif
                    if (displayName) *displayName =quotedText;
                    
                }
                break;
            }
            case '<':{
                [self scanAngularAddrSpecIntoLocalName:localName domain:domain error:&internalError];
                
                break;
            }
            case ',':{
                foundDelimiter = YES;
                [self advance:1];
                break;
            }
            default:{
                
                NSString * groupName = nil;
                NSString * addressListString= nil;
                if ([self scanGroupIntoGroupName:&groupName addresses:&addressListString error:&internalError]){
#ifdef DEBUG_RFC2822_SCANNER
                    NSLog (@"Group Name: %@ list: %@",groupName,addressListString);
#endif
                    continue;
                }
                
                NSString * phrase = nil;
#ifdef STRICT_RFC2822_COMPLIANCE
                
                // Strict compliance
                // the phrase portion of the address (ie portion prior to first occurance of '<' must be a valid RFC2822 phrase
                // eg the line
                //        name@host.domain <name@host.domain>
                // will NOT parse as a valid RFC2822 address because the initial '@' is not a valid
                // character for the phrase portion of adddress.
                // whereas
                //        "name@host.domain" <name@host.domain>
                // will parse as valid because phrase portion is a quoted string (as it should be)
                
                if ([self scanPhraseIntoString:&phrase]){
#ifdef DEBUG_RFC2822_SCANNER
                    NSLog (@"phrase: %@",phrase);
#endif
                    if (displayName) *displayName = phrase;
                }
#else  
                // not strict compliance
                //
                // scanner will treat any initial portion of string up to first occurances of '<' character to be a valid phrase
                // eg the line
                //        name@host.domain <name@host.domain>
                // will parse as a valid RFC2822 address even through it is technically  not valid because the initial '@' is not a valid
                // character for the phrase portion of adddress.
                //
                
                if( displayName ){
                    if ([self scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<,"] intoString:&phrase]){
                        phrase = [phrase stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                        if (!*displayName){
                            *displayName = phrase;
                        }
                        else if (previousWordWasMimeEncoded){
                            // append current phrase to existing display name with space
                            *displayName = [NSString stringWithFormat:@"%@ %@",*displayName,phrase];
                            previousWordWasMimeEncoded = NO;
                        }
                    }
#endif
                }
            }
                
        }
        [self scanFoldingWhiteSpace];
        
    }// while
    if (internalError){
        self.scanLocation = startLocation;
        if (error) *error = internalError;
    }
    return self.scanLocation>startLocation;
}

@end
