//
//  FileManager.m
//  Arch
//
//  Created by m4mm on 11/10/25.
//

#import "FileManager.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const kCookieManagerBaseURL = @"http://192.168.0.135:3000";
static NSString * const kNginxBaseURL = @"http://192.168.0.135";
static NSString * const kProtectedPath = @"/node_access_control";
static NSString * const kSessionCookieName = @"sessionId";

@implementation FileManager

+ (instancetype)defaultManager {
    static FileManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Initialization code here
    }
    return self;
}

- (void)loginWithUsername:(NSString *)username
                  password:(NSString *)password
                completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    if (!username || !password) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"FileManagerErrorDomain"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"Username and password are required"}];
            completion(NO, error);
        }
        return;
    }
    
    // Construct the login URL
    NSURL *loginURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/login", kCookieManagerBaseURL]];
    
    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:loginURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    // Create JSON body
    NSDictionary *bodyDict = @{
        @"username": username,
        @"password": password
    };
    
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:bodyDict
                                                       options:0
                                                         error:&jsonError];
    
    if (jsonError) {
        if (completion) {
            completion(NO, jsonError);
        }
        return;
    }
    
    [request setHTTPBody:jsonData];
    
#if DEBUG
    // Debug logging for login request
    NSLog(@"[FileManager] Login Request - URL: %@", loginURL);
    NSLog(@"[FileManager] Login Request - Username: %@", username);
    NSLog(@"[FileManager] Login Request - Password: %@", [password length] > 0 ? @"***" : @"(empty)");
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    NSLog(@"[FileManager] Login Request - JSON Body: %@", jsonString);
#endif
    
    // Create session configuration to handle cookies
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // Perform the request
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                             completionHandler:^(NSData * _Nullable data,
                                                                 NSURLResponse * _Nullable response,
                                                                 NSError * _Nullable error) {
        if (error) {
#if DEBUG
            // Debug logging for network error
            NSLog(@"[FileManager] Network Error: %@", error.localizedDescription);
            NSLog(@"[FileManager] Network Error Domain: %@", error.domain);
            NSLog(@"[FileManager] Network Error Code: %ld", (long)error.code);
            if (error.userInfo) {
                NSLog(@"[FileManager] Network Error UserInfo: %@", error.userInfo);
            }
#endif
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO, error);
                }
            });
            return;
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        if (httpResponse.statusCode == 200) {
            // Parse response
            if (!data) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSError *error = [NSError errorWithDomain:@"FileManagerErrorDomain"
                                                         code:-1
                                                     userInfo:@{NSLocalizedDescriptionKey: @"No response data received"}];
                    if (completion) {
                        completion(NO, error);
                    }
                });
                return;
            }
            
            NSError *parseError = nil;
            NSDictionary *responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                                          options:0
                                                                            error:&parseError];
            
            if (parseError) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(NO, parseError);
                    }
                });
                return;
            }
            
            // Check if login was successful
            BOOL success = [responseDict[@"success"] boolValue];
            
            if (success) {
                // Cookies are automatically stored by NSURLSession in NSHTTPCookieStorage
                // Verify that the session cookie was set
                NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:loginURL];
                BOOL hasSessionCookie = NO;
                NSHTTPCookie *sessionCookie = nil;
                for (NSHTTPCookie *cookie in cookies) {
                    if ([cookie.name isEqualToString:kSessionCookieName]) {
                        hasSessionCookie = YES;
                        sessionCookie = cookie;
                        break;
                    }
                }
                
#if DEBUG
                // Debug logging for cookie session response
                NSLog(@"[FileManager] Login Response - Status: %ld", (long)httpResponse.statusCode);
                NSLog(@"[FileManager] Login Response - JSON: %@", responseDict);
                NSLog(@"[FileManager] Cookies for URL: %@", cookies);
                if (sessionCookie) {
                    NSLog(@"[FileManager] Session Cookie Found:");
                    NSLog(@"  - Name: %@", sessionCookie.name);
                    NSLog(@"  - Value: %@", sessionCookie.value);
                    NSLog(@"  - Domain: %@", sessionCookie.domain);
                    NSLog(@"  - Path: %@", sessionCookie.path);
                    NSLog(@"  - Expires: %@", sessionCookie.expiresDate ?: @"Session cookie (no expiration)");
                    NSLog(@"  - Secure: %@", sessionCookie.isSecure ? @"YES" : @"NO");
                    NSLog(@"  - HTTPOnly: %@", sessionCookie.isHTTPOnly ? @"YES" : @"NO");
                } else {
                    NSLog(@"[FileManager] WARNING: Session cookie not found in cookie storage");
                }
                NSLog(@"[FileManager] Total cookies stored: %lu", (unsigned long)cookies.count);
#endif
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) {
                        completion(hasSessionCookie, nil);
                    }
                });
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *errorMessage = responseDict[@"message"] ?: @"Login failed";
                    NSError *error = [NSError errorWithDomain:@"FileManagerErrorDomain"
                                                         code:httpResponse.statusCode
                                                     userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
                    if (completion) {
                        completion(NO, error);
                    }
                });
            }
        } else {
            // Handle error response
            NSString *errorMessage = @"Login failed";
            NSDictionary *responseDict = nil;
            
            if (data) {
                NSError *parseError = nil;
                responseDict = [NSJSONSerialization JSONObjectWithData:data
                                                               options:0
                                                                 error:&parseError];
                
                if (responseDict && responseDict[@"message"]) {
                    errorMessage = responseDict[@"message"];
                } else if (httpResponse.statusCode == 401) {
                    errorMessage = @"Invalid username or password";
                }
            } else if (httpResponse.statusCode == 401) {
                errorMessage = @"Invalid username or password";
            }
            
#if DEBUG
            // Debug logging for error response
            NSLog(@"[FileManager] Login Failed - Status: %ld", (long)httpResponse.statusCode);
            NSLog(@"[FileManager] Login Failed - Error Message: %@", errorMessage);
            if (responseDict) {
                NSLog(@"[FileManager] Login Failed - Response JSON: %@", responseDict);
            }
            if (data) {
                NSString *responseString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"[FileManager] Login Failed - Raw Response: %@", responseString);
            }
#endif
            
            NSError *loginError = [NSError errorWithDomain:@"FileManagerErrorDomain"
                                                      code:httpResponse.statusCode
                                                  userInfo:@{NSLocalizedDescriptionKey: errorMessage}];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion) {
                    completion(NO, loginError);
                }
            });
        }
    }];
    
    [task resume];
}

- (void)fetchFileAtPath:(NSString *)filePath
             completion:(void (^)(NSData * _Nullable data, NSHTTPURLResponse * _Nullable response, NSError * _Nullable error))completion {
    
    if (!filePath || [filePath length] == 0) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"FileManagerErrorDomain"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: @"File path is required"}];
            completion(nil, nil, error);
        }
        return;
    }
    
    // Construct the full URL: http://192.168.0.135/node_access_control/filename
    // Remove leading slash from filePath if present to avoid double slashes
    NSString *cleanPath = [filePath hasPrefix:@"/"] ? [filePath substringFromIndex:1] : filePath;
    NSString *fullPath = [NSString stringWithFormat:@"%@%@/%@", kNginxBaseURL, kProtectedPath, cleanPath];
    NSURL *fileURL = [NSURL URLWithString:fullPath];
    
    if (!fileURL) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:@"FileManagerErrorDomain"
                                                 code:-1
                                             userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Invalid URL: %@", fullPath]}];
            completion(nil, nil, error);
        }
        return;
    }
    
#if DEBUG
    // Debug logging for file request
    NSLog(@"[FileManager] Fetching File - URL: %@", fileURL);
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:fileURL];
    NSLog(@"[FileManager] Cookies for URL: %lu", (unsigned long)cookies.count);
    for (NSHTTPCookie *cookie in cookies) {
        NSLog(@"[FileManager] Cookie: %@ = %@", cookie.name, cookie.value);
    }
#endif
    
    // Create the request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:fileURL];
    [request setHTTPMethod:@"GET"];
    
    // Create session configuration to handle cookies
    // NSHTTPCookieStorage will automatically include cookies for matching domains
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    // Perform the request
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                             completionHandler:^(NSData * _Nullable data,
                                                                 NSURLResponse * _Nullable response,
                                                                 NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
#if DEBUG
        // Debug logging for file response
        if (error) {
            NSLog(@"[FileManager] File Request Error: %@", error.localizedDescription);
        } else {
            NSLog(@"[FileManager] File Response - Status: %ld", (long)httpResponse.statusCode);
            NSLog(@"[FileManager] File Response - Content-Type: %@", httpResponse.allHeaderFields[@"Content-Type"] ?: @"unknown");
            NSLog(@"[FileManager] File Response - Content-Length: %@", httpResponse.allHeaderFields[@"Content-Length"] ?: @"unknown");
            if (data) {
                NSLog(@"[FileManager] File Response - Data Size: %lu bytes", (unsigned long)data.length);
            }
        }
#endif
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(data, httpResponse, error);
            }
        });
    }];
    
    [task resume];
}

@end

NS_ASSUME_NONNULL_END
