//
//  FileManager.h
//  Arch
//
//  Created by m4mm on 11/10/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FileManager : NSObject

+ (instancetype)defaultManager;

- (void)loginWithUsername:(NSString *)username
                  password:(NSString *)password
                completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

- (void)fetchFileAtPath:(NSString *)filePath
             completion:(void (^)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
