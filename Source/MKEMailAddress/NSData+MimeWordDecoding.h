//
//  NSData+MimeWordDecoding.h
//  MKEmailAddress
//
//  Created by smorr on 2015-09-04.
//  Copyright © 2015 indev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MimeWordDecoding)
+(NSData*)dataForMimeEncodedWord:(NSString*) word usedEncoding:(NSStringEncoding*) encoding;
@end
