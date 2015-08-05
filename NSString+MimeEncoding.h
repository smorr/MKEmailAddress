//
//  NSString+MimeEncoding.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (MimeEncoding)
+ (NSString*) stringWithMimeEncodedWord:(NSString*)word;
-(NSString*)decodedMimeEncodedString;
@end

