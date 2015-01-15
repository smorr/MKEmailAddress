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


@implementation NSString (MimeEncoding)

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
    
    if ([[word substringWithRange:NSMakeRange(i + 1, 2)] isEqualToString:@"Q?"])
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
                else
                    return nil;
                // low-order hex char
                h = [encodedString characterAtIndex:++i];
                if ((h >= '0') && (h <= '9'))
                    val += (int)(h - '0');
                else if ((h >= 'A') && (h <= 'F'))
                    val += (int)(h + 10 - 'A');
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
    else if ([[word substringWithRange:NSMakeRange(i + 1, 2)] isEqualToString:@"B?"]) {
        encodedString = [word substringWithRange:NSMakeRange(i + 3, word.length - i - 5)];
        NSData * decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:0];
        NSString * decodedString = [[NSString alloc] initWithData:decodedData encoding:encoding];
        return decodedString;
    }
    else
        return nil;
}

@end
