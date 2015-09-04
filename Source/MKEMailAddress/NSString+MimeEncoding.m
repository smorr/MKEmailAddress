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


@implementation NSString (MimeEncoding)
+ (NSString*) mimeWordWithString:(NSString*) string preferredEncoding:(NSStringEncoding)encoding encodingUsed:(NSStringEncoding*)usedEncoding{
    NSStringEncoding attemptedEncoding = encoding;
    
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
    if (attemptedEncoding){
        NSString * encodedString = [string stringByAddingPercentEscapesUsingEncoding:attemptedEncoding];
        encodedString = [encodedString stringByReplacingOccurrencesOfString:@"%" withString:@"="];
        encodedString = [encodedString stringByReplacingOccurrencesOfString:@" " withString:@"=20"];
        NSString * encodingName = nil;
        switch(attemptedEncoding){
            case NSISOLatin1StringEncoding:
                    encodingName=@"iso-8859-1";
                    break;
            case NSISOLatin2StringEncoding:
                    encodingName=@"iso-8859-2";
                    break;
            case NSUTF8StringEncoding:
                    encodingName=@"utf-8";
                    break;
            case NSUTF16StringEncoding:
                    encodingName=@"utf-16";
                    break;
        }
        if (encodingName){
            if (usedEncoding) *usedEncoding = attemptedEncoding;
            // string needs to be broken up into different mime words if length exceeds 76 char
            return [NSString stringWithFormat:@"=?%@?Q?%@?=",encodingName,encodedString];
        }
     }
    
    NSData * dataFromString = [string dataUsingEncoding:NSUTF8StringEncoding];
    NSString * base64String = [dataFromString base64EncodedStringWithOptions:0];
    if (usedEncoding) *usedEncoding = NSUTF8StringEncoding;
    return [NSString stringWithFormat:@"=?utf-8?B?%@?=",base64String];
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
    NSString *encodedString;
    
    if ([[word substringWithRange:NSMakeRange(i + 1, 2)] caseInsensitiveCompare:@"Q?"] == NSOrderedSame)
    {
        // quoted-printable
        encodedString = [word substringWithRange:NSMakeRange(i + 3, word.length - i - 5)];
        NSMutableData *binaryString = [[NSMutableData alloc] initWithLength:encodedString.length] ;
        unsigned char *binaryBytes = (unsigned char*)[binaryString mutableBytes];
        int j = 0;
        char h;
        
        for (i = 0; i < encodedString.length; i++)
        {
            unichar ch = [encodedString characterAtIndex:i];
            if (ch == (unichar)'_')
                binaryBytes[j++] = ' ';
            else if (ch == (unichar)'=')
            {
                if (i >= encodedString.length - 2)
                    return nil;
                
                unsigned char val = 0;
                
                // high-order hex char
                h = [encodedString characterAtIndex:++i];
                if ((h >= '0') && (h <= '9'))
                    val += ((int)(h - '0')) << 4;
                else if ((h >= 'A') && (h <= 'F'))
                    val += ((int)(h + 10 - 'A')) << 4;
                else if ((h >= 'a') && (h <= 'f'))
                    val += ((int)(h + 10 - 'a')) << 4;
                else
                    return nil;
                // low-order hex char
                h = [encodedString characterAtIndex:++i];
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
    NSString * decodedChunk =  [[NSString alloc] initWithData:fullDecodedData encoding:dataEncoding];
    if (decodedChunk){
        [decodedString appendString: decodedChunk];
    }
    return [NSString stringWithString:decodedString];
}

@end

