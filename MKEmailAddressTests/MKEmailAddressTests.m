//
//  MKEmailAddressTests.m
//  MKEmailAddressTests
//
//  Created by smorr on 2015-08-05.
//  Copyright © 2015 indev. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "MKEmailAddress.h"
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

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    NSString * testAddressPath = [[NSBundle  bundleForClass:[self class]] pathForResource:@"testAddresses" ofType:@"txt"];
    NSString * testAddresses  =  [NSString stringWithContentsOfFile:testAddressPath encoding:NSUTF8StringEncoding error:nil];
    [testAddresses enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
        NSArray <MKEmailAddress *> * emailAddresses = [MKEmailAddress emailAddressesFromHeaderValue:line];
        NSLog (@"EmailAddresses: %@",emailAddresses);
    }];
 
    
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
