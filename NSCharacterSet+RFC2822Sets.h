//
//  NSCharacterSet+RFC2822Sets.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (RFC2822Sets)
+(NSCharacterSet*)rfc2822TextSet;       // valid characters for char following escape char '/' for quoted pair
+(NSCharacterSet*)rfc2822CTextSet;      // valid characters for contents of comment unit
+(NSCharacterSet*)rfc2822QTextSet;      // valid characters for contents of quoted-String unit
+(NSCharacterSet*)rfc2822atomTextSet;   // valid characters for an atom unit
+(NSCharacterSet*)rfc2822dotAtomTextSet; // valid characters for a dotAtom unit
@end
