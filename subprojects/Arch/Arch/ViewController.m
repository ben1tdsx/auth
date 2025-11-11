//
//  ViewController.m
//  Arch
//
//  Created by m4mm on 11/10/25.
//

#import "ViewController.h"
#import "FileManager.h"

#ifndef U7Log
#define U7Log NSLog
#endif
#ifndef U7ErrorLog
#define U7ErrorLog U7Log
#endif

#ifndef U7Error
#define U7Error(n, ...) {error = [NSString stringWithFormat:n, ## __VA_ARGS__]; goto ERROR;}
#endif


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Disable text field editing on Apple TV - UITextField doesn't work properly on tvOS
    // Instead, we'll use UIAlertController for text input
    usernameField.enabled = NO;
    usernameField.userInteractionEnabled = NO;
    passwordField.enabled = NO;
    passwordField.userInteractionEnabled = NO;
    passwordField.secureTextEntry = YES;
    
    [userButton setTitle:@"User" forState:UIControlStateNormal];
    [passwordButton setTitle:@"Password" forState:UIControlStateNormal];


    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSString *lastUsername = [sud objectForKey:@"lastUsername"];
    if ([lastUsername length]) {
        
        usernameField.text = lastUsername;
    }
    
    
#if DEBUG

    passwordField.text = @"23";

#endif
    
    
    // Set up tap gesture recognizers for text fields
    UITapGestureRecognizer *usernameTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleUsernameFieldTap:)];
    [usernameField addGestureRecognizer:usernameTap];
    
    UITapGestureRecognizer *passwordTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handlePasswordFieldTap:)];
    [passwordField addGestureRecognizer:passwordTap];
    
    U7Log(@"<%p>%s: usernameField: %p", self, __PRETTY_FUNCTION__, usernameField);
    U7Log(@"<%p>%s: passwordField: %p", self, __PRETTY_FUNCTION__, passwordField);

}

- (void)handleUsernameFieldTap:(UITapGestureRecognizer *)gesture {
    // Show alert controller for username input
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Username"
                                                                   message:@"Enter your username"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Username";
        textField.text = self->usernameField.text;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        NSCharacterSet *set = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSString *username = [textField.text stringByTrimmingCharactersInSet:set];
        
        if ([username length]) {
            
            self->usernameField.text = username;
            
            NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
            [sud setObject:textField.text forKey:@"lastUsername"];
            [sud synchronize];

        }
        
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)handlePasswordFieldTap:(UITapGestureRecognizer *)gesture {
    // Show alert controller for password input
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Password"
                                                                   message:@"Enter your password"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Password";
        textField.secureTextEntry = YES;
        textField.text = self->passwordField.text;
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITextField *textField = alert.textFields.firstObject;
        self->passwordField.text = textField.text;
    }];
    
    [alert addAction:cancelAction];
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}


- (NSArray<id<UIFocusEnvironment>> *)preferredFocusEnvironments {
    U7Log(@"<%p>%s", self, __PRETTY_FUNCTION__);
    return @[loginButton, userButton, passwordButton];
}

- (IBAction)buttonAction:(UIButton *)sender {
    
    if (sender == userButton)
        [self handleUsernameFieldTap:nil];
    else if (sender == passwordButton)
        [self handlePasswordFieldTap:nil];

        
        
    U7Log(@"<%p>%s: sender: %p title: %@", self, __PRETTY_FUNCTION__, sender, [sender titleForState:UIControlStateNormal]);
    
    
}


- (IBAction)loginAction:(id)sender {
    
    NSString *username = [usernameField text];
    NSString *password = [passwordField text];
    U7Log(@"<%p>%s|username %@|password %lu", self, __PRETTY_FUNCTION__, username, [password length]);
   
    FileManager *mngr = [FileManager defaultManager];
    
    [mngr loginWithUsername:username password:@"23" completion:^(BOOL success, NSError * _Nullable error) {
        
        
        U7Log(@"<%p>%s: success: %i", self, __PRETTY_FUNCTION__, success);
        
    }];
    
    
}


@end
