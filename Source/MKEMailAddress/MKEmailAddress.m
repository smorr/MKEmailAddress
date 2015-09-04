//
//  MKEmailAddress.m
//  EmailAddressParser
//
//  Created by smorr on 2015-01-15.
//  Copyright (c) 2015 Indev Software. All rights reserved.
//

#if ! __has_feature(objc_arc)
#error This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif


#import "MKEmailAddress.h"

#import "NSScanner+RFC2822.h"
#import "NSString+MimeEncoding.h"


@implementation MKEmailAddress

-(instancetype) initWithAddressComment:(NSString*)commentPart userName:(NSString*) userPart domain:(NSString*)domainPart {
    self = [super init];
    if (self){
        self.addressComment =commentPart;
        self.userName = userPart;
        self.domain = domainPart;
    }
    return self;
}

-(instancetype) initWithCommentedAddress:(NSString*)commentedAddress{
    self = [self init];
    NSScanner * scanner = [NSScanner scannerWithString:commentedAddress];
    NSString * displayName= nil;
    NSString * userName = nil;
    NSString * domain = nil;
    NSError * error = nil;
    [scanner scanRFC2822EmailAddressIntoDisplayName:&displayName localName:&userName domain:&domain error:&error];
    self.addressComment = displayName;
    self.userName = userName;
    self.domain = domain;
    return self;
    
}

+(NSString*)rfc2822RepresentationForAddresses:(MKEmailAddressArray *)addresses{
    NSMutableArray * rfc2822Reps = [NSMutableArray array];
    for (MKEmailAddress* anAddr in addresses){
        NSString * rfcRep = [anAddr rfc2822Representation];
        if (rfcRep){
            [rfc2822Reps addObject:rfcRep];
        }
    }
    if ([rfc2822Reps count]){
        return [rfc2822Reps componentsJoinedByString:@","];
    }
    return nil;
}

+(NSArray*)emailAddressesFromHeaderValue:(NSString*)headerValue{
    if (!headerValue) return nil;
    NSMutableArray * emailAddresses = [NSMutableArray array];
    @autoreleasepool {
        NSScanner * scanner = [NSScanner scannerWithString:headerValue];
        NSString * displayName= nil;
        NSString * userName = nil;
        NSString * domain = nil;
        NSError * error = nil;
         while (![scanner isAtEnd] && !error){
            if([scanner scanRFC2822EmailAddressIntoDisplayName:&displayName localName:&userName domain:&domain error:&error]){
                if (displayName||(userName && domain)){
                    NSString * decodedDisplayName = [displayName decodedMimeEncodedString];
                    MKEmailAddress * address = [[MKEmailAddress alloc] initWithAddressComment:decodedDisplayName userName:userName domain:domain];
                    [emailAddresses addObject:address];
                }
            }
            else{
                NSLog(@"\n\t\t%@\n\t\t\t\tERROR: %@",headerValue,error);
                emailAddresses = nil;
                break;
            }
        }
    }
    return emailAddresses;    
}

#pragma mark NSCopying, Equality 

-(MKEmailAddress*)copyWithZone:(NSZone*)aZone{
    MKEmailAddress* theCopy = [[MKEmailAddress alloc] initWithAddressComment:self.addressComment userName:self.userName domain:self.domain];
    return theCopy;
}

-(BOOL) isEqualTo:(id)object{
    if ([object isKindOfClass:[MKEmailAddress class]]){
        return [self.commentedAddress isEqualToString:[(MKEmailAddress*)object commentedAddress]];
    }
    else {
        return NO;
    }
}
-(BOOL) isEqual:(id)object{
    if ([object isKindOfClass:[MKEmailAddress class]]){
        return [self.commentedAddress isEqualToString:[(MKEmailAddress*)object commentedAddress]];
    }
    else {
        return NO;
    }
}


-(NSUInteger) hash{
    return [self.commentedAddress hash];
}


#pragma mark -
-(NSString*)rfc2822Representation{
    if (self.addressComment){
        if (self.userAtDomain){
            if ([self.addressComment canBeConvertedToEncoding:NSASCIIStringEncoding]){
                return [NSString stringWithFormat:@"\"%@\" <%@>",self.addressComment,self.userAtDomain];
            }
            else{
                NSString * encodedComment = [NSString mimeWordWithString:self.addressComment preferredEncoding:NSISOLatin1StringEncoding encodingUsed:nil];
                return [NSString stringWithFormat:@"\"%@\" <%@>",encodedComment,self.userAtDomain];
            }
        }
        else{
            // technically this is not RFC2822 compliant as there is no user@domain portion
            if ([self.addressComment canBeConvertedToEncoding:NSASCIIStringEncoding]){
                return [NSString stringWithFormat:@"\"%@\"",self.addressComment];
            }
            else{
                NSString * encodedComment = [NSString mimeWordWithString:self.addressComment preferredEncoding:NSISOLatin1StringEncoding encodingUsed:nil];
                return [NSString stringWithFormat:@"\"%@\"",encodedComment];
            }

        }
    }
    else{
        return self.userAtDomain;
    }
}

-(NSString*)commentedAddress{
    if (self.addressComment){
        if (self.userAtDomain){
            return [NSString stringWithFormat:@"%@ <%@>",self.addressComment,self.userAtDomain];
        }
    }
    else{
        return self.userAtDomain;
    }
    return nil;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"<%@: %p> %@",[self class],self,[self commentedAddress]];
}

-(NSString*)userAtDomain{
    if (self.userName && self.domain){
        return [NSString stringWithFormat:@"%@@%@",self.userName, self.domain];
    }
    return nil;
}

-(NSString*)displayName{
    return [self.addressComment decodedMimeEncodedString]?:self.userAtDomain;
}
-(BOOL)isValid{
    return YES;
}
@end

