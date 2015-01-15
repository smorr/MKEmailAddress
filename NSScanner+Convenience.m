//
//  NSScanner+Convenience.m
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "NSScanner+Convenience.h"

@implementation NSScanner (Convenience)
-(NSString*)remainder{
    return [self.string substringFromIndex:self.scanLocation];
}
-(unichar)currentCharacter{
    if ([self isAtEnd]) return 0;
    return [[self string] characterAtIndex:[self scanLocation]];
}
-(unichar)characterAtOffset:(NSInteger)offset{
    if (self.scanLocation+offset>=[self.string length]) return 0;
    if ((NSInteger)(self.scanLocation+offset)<0) return 0 ;
    return [self.string characterAtIndex:self.scanLocation+offset];
}

-(NSUInteger)advance:(NSUInteger)characterCount{
    // advanced specified characters -- returns the number of characters actually advanced.
    if ([self isAtEnd]) return 0;
    NSUInteger startLocation = [self scanLocation];
    NSUInteger newlocation = MIN(startLocation+characterCount,[[self string]length]);
    [self setScanLocation:newlocation];
    return (newlocation - startLocation);
}
-(NSUInteger)rewind:(NSUInteger)characterCount{
    // rewinds specified characters -- returns the number of characters actually rewound.
    if ([self scanLocation]==0) return 0;
    NSUInteger startLocation = [self scanLocation];
    NSUInteger newlocation = MAX(startLocation-characterCount,0);
    [self setScanLocation:newlocation];
    return (startLocation-newlocation);
}
@end
