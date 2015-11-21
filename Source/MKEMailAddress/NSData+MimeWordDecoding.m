//
//  NSData+MimeWordDecoding.m
//  MKEmailAddress
//
//  Created by smorr on 2015-09-04.
//  Copyright © 2015 indev. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NSData+MimeWordDecoding.h"

@implementation NSData (MimeWordDecoding)
+(NSData*)dataForMimeEncodedWord:(NSString*) word usedEncoding:(NSStringEncoding*) usedEncoding{
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
    if (usedEncoding) * usedEncoding = encoding;
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
        
        [binaryString setLength:j];
        
        return binaryString;
        
    }
    else if ([[word substringWithRange:NSMakeRange(i + 1, 2)] caseInsensitiveCompare:@"B?"] == NSOrderedSame) {
        encodedString = [word substringWithRange:NSMakeRange(i + 3, word.length - i - 5)];
        NSData * decodedData = [[NSData alloc] initWithBase64EncodedString:encodedString options:NSDataBase64DecodingIgnoreUnknownCharacters];
        return decodedData;
    }
    else
        return nil;
}
@end