//
//  MKEmailAddressTests.m
//  MKEmailAddressTests
//
//  Created by smorr on 2015-08-05.
//  Copyright © 2015 indev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MKEmailAddress.h"
#import "NSString+MimeEncoding.h"

@interface MKEmailAddressTests : XCTestCase

@end

@implementation MKEmailAddressTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMimeDecode{
    NSString * mimeEncode = @"=?utf-8?B?UGVyc29uYWwgU2VydmljZXMgQnVzaW5lc3MgVGF4IEhpa2UgQmVjb21pbmcgTGF3IOI=?=\n    =?utf-8?B?gJQgVGltZSBmb3IgYSBOZXcgUGxhbg==?=";
    NSString * decoded = [mimeEncode decodedMimeEncodedString];
    NSLog (@"decoded: %@",decoded);
}
- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSString * testAddressPath = [[NSBundle  bundleForClass:[self class]] pathForResource:@"testAddresses" ofType:@"txt"];
    NSString * testAddresses  =  [NSString stringWithContentsOfFile:testAddressPath encoding:NSUTF8StringEncoding error:nil];
    [testAddresses enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSString * line2 = [line stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n" options:0 range:NSMakeRange(0,line.length)];
        NSArray <MKEmailAddress *> * emailAddresses = [MKEmailAddress emailAddressesFromHeaderValue:line2];
        NSLog (@"EmailAddresses: %@",[emailAddresses valueForKey:@"rfc2822Representation"]);
    }];
 
    
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
