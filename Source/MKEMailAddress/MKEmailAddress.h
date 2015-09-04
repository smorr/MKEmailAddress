//
//  MKEmailAddress.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MKEmailAddress;

typedef NSArray <MKEmailAddress*> MKEmailAddressArray;
typedef NSMutableArray <MKEmailAddress*> MKEmailAddressMutableArray;

@interface MKEmailAddress:NSObject <NSCopying>

@property(strong) NSString * addressComment;
@property(strong) NSString * userName;
@property(strong) NSString * domain;
@property(readonly) NSString * commentedAddress;
@property(readonly) NSString * userAtDomain;
@property(readonly) NSString * displayName;

#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER 
#endif
-(instancetype) initWithAddressComment:(NSString*)commentPart userName:(NSString*) userPart domain:(NSString*)domainPart ;
-(instancetype) initWithCommentedAddress:(NSString*)commentedAddress;
+(NSString*)rfc2822RepresentationForAddresses:(MKEmailAddressArray *)addresses;
+(MKEmailAddressArray*)emailAddressesFromHeaderValue:(NSString*)headerValue;
-(NSString*)rfc2822Representation;
-(BOOL)isValid;
@end

