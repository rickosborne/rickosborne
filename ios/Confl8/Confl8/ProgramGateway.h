//
//  ProgramGateway.h
//  Confl8
//
//  Created by rosborne on 5/19/12.
//

#import <Foundation/Foundation.h>

@protocol ProgramGateway <NSObject>

- (void)authenticateWithDelegate:(id)target onSuccess:(NSString *)success onFailure:(NSString *)failure;

@end
