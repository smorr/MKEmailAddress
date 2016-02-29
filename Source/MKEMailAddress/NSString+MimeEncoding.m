//
//  NSString+MimeEncoding.m
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

/*
 Portions of code are taken from http://stackoverflow.com/a/14014839/922658
 No licence information provided.
 */

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NSString+MimeEncoding.h"
#import "NSData+MimeWordDecoding.h"

const NSInteger kQuotedPrintableLineLength = 76;

@implementation NSString (MimeEncoding)

+ (NSString*) quotedPrintableStringWithString:(NSString *)string preferredEncoding:(NSStringEncoding)preferredEncoding encodingUsed:(NSStringEncoding *)usedEncoding{
    
    NSStringEncoding attemptedEncoding = preferredEncoding;
    if (![string canBeConvertedToEncoding:attemptedEncoding]) {
        attemptedEncoding = 0;
        if([string canBeConvertedToEncoding:NSISOLatin2StringEncoding]){
            attemptedEncoding = NSISOLatin2StringEncoding;
        }
        else if ([string canBeConvertedToEncoding:NSUTF8StringEncoding]){
            attemptedEncoding = NSUTF8StringEncoding;
        }
        else if ([string canBeConvertedToEncoding:NSUTF16StringEncoding]){
            attemptedEncoding = NSUTF16StringEncoding;
        }
    }
    if (usedEncoding) *usedEncoding = attemptedEncoding;
    if (attemptedEncoding){
        // make it quotedPrintable
            // string needs to be broken up into different mime words if length exceeds 76 char
        static NSCharacterSet * allowedCharSet = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableCharacterSet * charSet = [[NSCharacterSet letterCharacterSet] mutableCopy];
            [charSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
            [charSet addCharactersInString:@"%\r\n"];
            allowedCharSet = [NSCharacterSet characterSetWithBitmapRepresentation:[charSet bitmapRepresentation]];
        });
        NSString * encodedString = [string stringByAddingPercentEscapesUsingEncoding:attemptedEncoding];
        NSString * quotedPrintable  = [encodedString stringByAddingPercentEncodingWithAllowedCharacters:allowedCharSet];
        
        quotedPrintable = [quotedPrintable stringByReplacingOccurrencesOfString:@"%20" withString:@"_"];
        quotedPrintable = [quotedPrintable stringByReplacingOccurrencesOfString:@"%" withString:@"="];
        return quotedPrintable;
    }
    else{
        return nil;
    }
}

+(NSString*)quotedPrintableStringForPlainTextBody:(NSString *)string preferredEncoding:(NSStringEncoding)preferredEncoding encodingUsed:(NSStringEncoding *)usedEncoding {
    NSString * quotedPrintable= nil;
        
    NSStringEncoding attemptedEncoding = preferredEncoding;
    if (![string canBeConvertedToEncoding:attemptedEncoding]) {
        attemptedEncoding = 0;
        if([string canBeConvertedToEncoding:NSISOLatin2StringEncoding]){
            attemptedEncoding = NSISOLatin2StringEncoding;
        }
        else if ([string canBeConvertedToEncoding:NSUTF8StringEncoding]){
            attemptedEncoding = NSUTF8StringEncoding;
        }
        else if ([string canBeConvertedToEncoding:NSUTF16StringEncoding]){
            attemptedEncoding = NSUTF16StringEncoding;
        }
    }
    if (usedEncoding) *usedEncoding = attemptedEncoding;
    if (attemptedEncoding){
        
        // encode the string into a NSData object with desired encoding
        // and output the dataObject as NSString object with non allowed characters escaped with =02X format.
        NSMutableString * muQuotedPrintableString = [NSMutableString string];
        
        NSData * encodedData = [string dataUsingEncoding:attemptedEncoding];
        NSUInteger len = encodedData.length;
        const char * bytesBuffer = [encodedData bytes];
        
        static NSMutableCharacterSet * charSet = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            charSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(32, 28)];
            [charSet addCharactersInRange:NSMakeRange(62, 64)];
            [charSet addCharactersInString:@"\r\n"];
            [charSet removeCharactersInString:@"!\"#$@[\\]^`{|}~"]; //EBCDIC characters  should be encoded for passing through
                // potential gateways.

        });
        for (int i = 0; i <len; i++){
            unsigned char currentChar =bytesBuffer[i];
            if ([charSet characterIsMember:currentChar]){
                [muQuotedPrintableString appendFormat:@"%c",currentChar];
            }
            else if (currentChar == 0x0f){ // ignoreShiftIn
                continue;
            }
            else{
                [muQuotedPrintableString appendFormat:@"=%02X", currentChar];
            }
        }
       // free(bytesBuffer);
        
        quotedPrintable = muQuotedPrintableString;
    }
    
    if (!quotedPrintable) return nil;
    
    //wrap the quotedPrintableString at 76 characters according to RFC 2045 (https://tools.ietf.org/html/rfc2045#section-6.7 )
    
    NSMutableArray * lines = [NSMutableArray array];
    NSUInteger curPosition = 0;
    NSUInteger lineStart = 0;
    NSString * lineSuffix = @"=";
    while( YES ){
        NSInteger currLineLength =  (curPosition - lineStart) + lineSuffix.length;
        
        if (curPosition < quotedPrintable.length){
            unichar c = [quotedPrintable characterAtIndex:curPosition]; // ok to use character size of 1 as string should be all 7bit ascii
            NSInteger maxLengthForCurrentLine = kQuotedPrintableLineLength;
            
            // see if the current characer is part 1 of a \r\n sequence
            // in which case finish the line and add it to the array lines, then continue.
            
            if (c == '\r' && curPosition+1 < quotedPrintable.length && [quotedPrintable characterAtIndex:curPosition+1]=='\n'){
                NSString * currentLine = [NSString stringWithFormat:@"%@",[quotedPrintable substringWithRange:NSMakeRange(lineStart, (curPosition-lineStart)-1)]];
                [lines addObject:currentLine];
                curPosition+=2;
                lineStart =curPosition;
                continue;
            }
            
            if (c == '=') maxLengthForCurrentLine = kQuotedPrintableLineLength - 3 ; // headers line cannot break =xx encoding, so shorten the max length by 3 chars
            
            if (currLineLength >= maxLengthForCurrentLine){
                
                NSString * currentLine = [NSString stringWithFormat:@"%@%@",[quotedPrintable substringWithRange:NSMakeRange(lineStart, (curPosition-lineStart))],lineSuffix];
                [lines addObject:currentLine];
                lineStart = curPosition;
            }
            else{
                curPosition++;
            }
        }
        else {
            NSString * currentLine = [NSString stringWithFormat:@"%@",[quotedPrintable substringWithRange:NSMakeRange(lineStart, (curPosition - lineStart))]];
            // if the last line ends in a space
            if ([currentLine characterAtIndex:currentLine.length-1] == ' '){
                if (currentLine.length == kQuotedPrintableLineLength){
                    currentLine = [string stringByReplacingCharactersInRange:NSMakeRange(kQuotedPrintableLineLength-1, 1) withString:@"="];
                    [lines addObject:currentLine];
                    [lines addObject:@" ="];
                }
                else{
                    currentLine = [currentLine  stringByAppendingString:@"="];
                    [lines addObject:currentLine];
                }
            }
            else{
                [lines addObject:currentLine];
            }
            break;
        }
    }
    return [lines componentsJoinedByString:@"\r\n"];;
}

+ (NSString*) MKcharSetNameForEncoding:(NSStringEncoding)encoding{
    CFStringEncoding cfEncoding = CFStringConvertNSStringEncodingToEncoding(encoding);
    return [(NSString*)CFStringConvertEncodingToIANACharSetName(cfEncoding) lowercaseString] ;
}

+ (NSStringEncoding) MKencodingForCharSetName:(NSString*)charSet{
    CFStringEncoding cfEncoding = CFStringConvertIANACharSetNameToEncoding((CFStringRef)charSet);
    return CFStringConvertEncodingToNSStringEncoding(cfEncoding);
}


+ (NSString*) mimeWordWithString:(NSString*) string preferredEncoding:(NSStringEncoding)encoding encodingUsed:(NSStringEncoding*)usedEncoding{
    
    NSStringEncoding myUsedEncoding = 0;
    NSString * encodedString = [self quotedPrintableStringWithString:string preferredEncoding:encoding encodingUsed:&myUsedEncoding];
    
    if (usedEncoding) *usedEncoding = myUsedEncoding;
    
    if (encodedString && myUsedEncoding){
        NSString * encodingName = [NSString MKcharSetNameForEncoding:myUsedEncoding];
        if (encodingName){
            return [NSString stringWithFormat:@"=?%@?Q?%@?=",encodingName,encodedString];
        }
    }
    if (usedEncoding) *usedEncoding = 0;
    return nil;
    // if we are here, it is either no 
}


+ (NSString*) stringWithMimeEncodedWord:(NSString*)word {
    // Example: =?iso-8859-1?Q?=A1Hola,_se=F1or!?=
    if (![word hasPrefix:@"=?"] || ![word hasSuffix:@"?="])
        return nil;
    
    int i = 2;
    while ((i < word.length) && ([word characterAtIndex:i] != (unichar)'?'))
        i++;
    
    if (i >= word.length - 4)
        return nil;
    
    NSString *encodingName = [word substringWithRange:NSMakeRange(2, i - 2)];
    NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding((CFStringRef)encodingName));
    // warning! can return 'undefined something' if encodingName is invalid or unknown
    if (encoding == kCFStringEncodingInvalidId){
        return nil;
    }
    NSString *encodedString = nil;
    
    if ([[word substringWithRange:NSMakeRange(i + 1, 2)] caseInsensitiveCompare:@"Q?"] == NSOrderedSame){
        // quoted-printable
        encodedString = [word substringWithRange:NSMakeRange(i + 3, word.length - i - 5)];
        NSMutableData *binaryString = [[NSMutableData alloc] initWithLength:encodedString.length] ;
        unsigned char *binaryBytes = (unsigned char*)[binaryString mutableBytes];
        int j = 0;
        char h;
        
        int encodedIndex = 0;
        
        while (encodedIndex < encodedString.length){
            unichar ch = [encodedString characterAtIndex:encodedIndex];
            if (ch == (unichar)'_'){
                binaryBytes[j++] = ' ';
            }
            else if (ch == (unichar)'='){
                if (encodedIndex >= encodedString.length - 2)
                    return nil;
                
                unsigned char val = 0;
                
                // high-order hex char
                encodedIndex++;
                if (encodedIndex >= encodedString.length) return nil;
                
                h = [encodedString characterAtIndex:encodedIndex];
                if ((h >= '0') && (h <= '9'))
                    val += ((int)(h - '0')) << 4;
                else if ((h >= 'A') && (h <= 'F'))
                    val += ((int)(h + 10 - 'A')) << 4;
                else if ((h >= 'a') && (h <= 'f'))
                    val += ((int)(h + 10 - 'a')) << 4;
                else
                    return nil;
                // low-order hex char
                encodedIndex++;
                if (encodedIndex >= encodedString.length) return nil;

                h = [encodedString characterAtIndex:encodedIndex];
                if ((h >= '0') && (h <= '9'))
                    val += (int)(h - '0');
                else if ((h >= 'A') && (h <= 'F'))
                    val += (int)(h + 10 - 'A');
                else if ((h >= 'a') && (h <= 'f'))
                    val += (int)(h + 10 - 'a');
                else
                    return nil;
                
                binaryBytes[j++] = val;
            }
            else if (ch < 256)
                binaryBytes[j++] = ch;
            else
                return nil;
            encodedIndex++;
        }
        
        binaryBytes[++j] = 0;
        [binaryString setLength:j];
        
        NSString *result = [[NSString alloc] initWithCString:[binaryString mutableBytes] encoding:encoding];
        // warning! can return 'undefined something' if encoding is invalid or unknown
        
        return result;
    }
    else if ([[word substringWithRange:NSMakeRange(i + 1, 2)] caseInsensitiveCompare:@"B?"] == NSOrderedSame) {
        encodedString = [word substringWithRange:NSMakeRange(i + 3, word.length - i - 5)];
        NSData * decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        NSString * decodedString = [[NSString alloc] initWithData:decodedData encoding:encoding];
        return decodedString;
    }
    else
        return nil;
}

-(NSString*)decodedMimeEncodedString{
    NSScanner * scanner = [NSScanner scannerWithString:self];
    [scanner setCharactersToBeSkipped:nil];
    [scanner setCaseSensitive:NO];
    NSMutableString * decodedString = [NSMutableString string];
    NSMutableData * fullDecodedData = [NSMutableData data];
    NSStringEncoding dataEncoding = 0;
    
    while (![scanner isAtEnd]){
        NSString * leadingWhiteSpace = nil;
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&leadingWhiteSpace];
    
        NSString * leadingString = nil;
        [scanner scanUpToString:@"=?" intoString:&leadingString];
        if (leadingString) {
            if (leadingWhiteSpace) [decodedString appendString:leadingWhiteSpace];
            [decodedString appendString:leadingString];
        }
        
        NSUInteger mimeStart = [scanner scanLocation];
        NSUInteger mimeEnd = NSNotFound;
        if ([scanner scanString:@"=?" intoString:nil]){
            [scanner scanUpToString:@"?" intoString:nil];  // scan the encoding
            if ([scanner scanString:@"?" intoString:nil]){
                if ([scanner scanString:@"B" intoString:nil] || [scanner scanString:@"Q" intoString:nil]){  // scans type
                     if ([scanner scanString:@"?" intoString:nil]){
                         [scanner scanUpToString:@"?=" intoString:nil];  // scans word
                         if ([scanner scanString:@"?=" intoString:nil])
                             mimeEnd = [scanner scanLocation];
                     }
                }
            }
        }
        if (mimeEnd != NSNotFound){
            NSString * mimeWord = [[scanner string] substringWithRange:NSMakeRange(mimeStart, mimeEnd-mimeStart)];
            NSStringEncoding wordEncoding = 0;
            NSData * decodedWordData = [NSData dataForMimeEncodedWord:mimeWord usedEncoding:&wordEncoding];
            if (dataEncoding==0){
                // this is first pass -- just append the data;
                dataEncoding = wordEncoding;
                [fullDecodedData appendData:decodedWordData];
            }
            else if (wordEncoding != dataEncoding){
                // this word has a different encoding than accumulated data
                // so convert the accumulated data to a string (using its encoding) and append to ongoing string.
                
                NSString * decodedChunk =  [[NSString alloc] initWithData:fullDecodedData encoding:dataEncoding];
                [decodedString appendString: decodedChunk];
                
                // and start accumulating data again with new encoding.
                dataEncoding = wordEncoding;
                [fullDecodedData setData:decodedWordData];
            }
            else{
                // same encoding as last chuck -- so just append the data.
                [fullDecodedData appendData:decodedWordData];
            }
        }
    }
    
    // if there is is any remaining accumulated data, decode into string and append to the wholeString
    if (fullDecodedData && dataEncoding){
        NSString * decodedChunk =  [[NSString alloc] initWithData:fullDecodedData encoding:dataEncoding];
        if (decodedChunk){
            [decodedString appendString: decodedChunk];
        }
    }
    return [NSString stringWithString:decodedString];
}

@end

