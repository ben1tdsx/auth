//
//  ViewController.h
//  Arch
//
//  Created by m4mm on 11/10/25.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    
    IBOutlet UITextField *usernameField, *passwordField;
    IBOutlet UIButton *loginButton, *userButton, *passwordButton;
}

- (IBAction)loginAction:(id)sender;
@end

