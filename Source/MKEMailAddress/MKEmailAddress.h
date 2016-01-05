//
//  MKEmailAddress.h
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#import <Foundation/Foundation.h>
@class MKEmailAddress;

#if __has_feature(objc_generics)

#define MKEmailAddressArray NSArray <MKEmailAddress*>
#define MKEmailAddressMutableArray NSMutableArray <MKEmailAddress*>

#else

#define MKEmailAddressArray NSArray
#define MKEmailAddressMutableArray NSMutableArray

#endif

@interface MKEmailAddress:NSObject <NSCopying>

@property(strong) NSString * addressComment;
@property(strong) NSString * userName;
@property(strong) NSString * domain;
@property(readonly) NSString * commentedAddress;
@property(readonly) NSString * userAtDomain;
@property(readonly) NSString * displayName;
@property(strong) NSString * invalidHeaderString;

#ifndef NS_DESIGNATED_INITIALIZER
#define NS_DESIGNATED_INITIALIZER 
#endif

-(instancetype) initWithInvalidHeaderString:(NSString*)headerString;
-(instancetype) initWithAddressComment:(NSString*)commentPart userName:(NSString*) userPart domain:(NSString*)domainPart ;
-(instancetype) initWithCommentedAddress:(NSString*)commentedAddress;
+(NSString*)rfc2822RepresentationForAddresses:(MKEmailAddressArray *)addresses;
+(MKEmailAddressArray*)emailAddressesFromHeaderValue:(NSString*)headerValue;
-(NSString*)rfc2822Representation;
-(BOOL)isValid;
@end

