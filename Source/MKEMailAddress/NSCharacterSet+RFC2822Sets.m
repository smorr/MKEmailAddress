//
//  NSCharacterSet+RFC2822Sets.m
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NSCharacterSet+RFC2822Sets.h"

@implementation NSCharacterSet (RFC2822Sets)

+(NSCharacterSet*)rfc2822TextSet{
    static NSCharacterSet * theSet= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet * mutableSet =[NSMutableCharacterSet characterSetWithRange:NSMakeRange(1,10)];
        [mutableSet addCharactersInRange:NSMakeRange(11,2)]; //0x0b, 0x0c
        [mutableSet addCharactersInRange:NSMakeRange(14,114)]; //%d14-127
        theSet= [NSCharacterSet characterSetWithBitmapRepresentation:[mutableSet bitmapRepresentation]];
    });
    return theSet;
}

+(NSCharacterSet*)rfc2822CTextSet{
    static NSCharacterSet * theSet= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet * mutableSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(1,9)];//NO_WS_CTL
        [mutableSet addCharactersInRange:NSMakeRange(11,2)]; //0x0b, 0x0c
        [mutableSet addCharactersInRange:NSMakeRange(14,18)]; //%d14-31
        [mutableSet addCharactersInRange:NSMakeRange(33,7)];//%d33-39
        [mutableSet addCharactersInRange:NSMakeRange(42,50)];//%d42-91
        [mutableSet addCharactersInRange:NSMakeRange(93,34)];//%d93-126;
        [mutableSet addCharactersInRange:NSMakeRange(127,1)]; //%d127
        
        theSet= [NSCharacterSet characterSetWithBitmapRepresentation:[mutableSet bitmapRepresentation]];
    });
    return theSet;
    
}
+(NSCharacterSet*)rfc2822QTextSet{
    static NSCharacterSet * theSet= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet * mutableSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(1,33)];
        [mutableSet addCharactersInRange:NSMakeRange(35,57)];  //%d35-91
        [mutableSet addCharactersInRange:NSMakeRange(93,34)];  //%d93-126;
        [mutableSet addCharactersInRange:NSMakeRange(127,1)];
        
        theSet= [NSCharacterSet characterSetWithBitmapRepresentation:[mutableSet bitmapRepresentation]];
    });
    return theSet;
}

+(NSCharacterSet*)rfc2822atomTextSet{
    /*
     atext           =       ALPHA / DIGIT / ; Any character except controls,
                             "!" / "#" /     ;  SP, and specials.
                             "$" / "%" /     ;  Used for atoms
                             "&" / "'" /
                             "*" / "+" /
                             "-" / "/" /
                             "=" / "?" /
                             "^" / "_" /
                             "`" / "{" /
                             "|" / "}" /
                             "~"
                             */
    static NSCharacterSet * theSet= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet * mutableSet = [NSMutableCharacterSet alphanumericCharacterSet];//NO_WS_CTL
        [mutableSet addCharactersInString:@"!#$%&'*+-/=?^_`{|}~"];
        
        theSet= [NSCharacterSet characterSetWithBitmapRepresentation:[mutableSet bitmapRepresentation]];
    });
    return theSet;
}

+(NSCharacterSet*)rfc2822dotAtomTextSet{
    static NSCharacterSet * theSet= nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet * mutableSet = [NSMutableCharacterSet alphanumericCharacterSet];//NO_WS_CTL
        [mutableSet addCharactersInString:@"!#$%&'*+-/=?^_`{|}~."];// nb. same as atom with '.'
        theSet= [NSCharacterSet characterSetWithBitmapRepresentation:[mutableSet bitmapRepresentation]];
    });
    return theSet;
}


@end
