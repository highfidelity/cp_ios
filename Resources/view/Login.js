/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for login screen.  This is shown as a modal dialog which slides down
 * from the header bar, takes the user's username/password, and initiates a login
 * with the CandP server
 * 
 */

(function() {
    candp.view.createLoginView = function () {
        var loginView = Ti.UI.createView(candp.combine($$.contained, {
            visible: false,
            // *TODO: investigate problems with Android detecting view visiblity
            showing: false,
            zIndex: 25
        }));


        // use a dialog container
        var containerView = Ti.UI.createView(candp.combine($$.smallSizeView, {
            top: 20,
            backgroundColor: '#DDDDDD',
            borderRadius: 15
        }));


        // email/username
        containerView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            top: 15,
            left: 15,
            textAlign: 'left',
            color: '#000000',
            text: L('email')
        })));

        var emailText = Ti.UI.createTextField(candp.combine($$.textField, {
            top: 40,
            left: 15,
            right: 15,
            autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_NONE,
            keyboardType: Titanium.UI.KEYBOARD_EMAIL,
            returnKeyType: Titanium.UI.RETURNKEY_DONE,
            value: Ti.App.Properties.getString('username', '')
        }));
       
        emailText.addEventListener('return', function() {
            passwordText.focus();
        });
        containerView.add(emailText);


        // password
        containerView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            top: 85,
            left: 15,
            textAlign: 'left',
            color: '#000000',
            text: L('password')
        })));

        var passwordText = Ti.UI.createTextField(candp.combine($$.textField, {
            top: 110,
            left: 15,
            right: 15,
            passwordMask: true,
            autocapitalization: Titanium.UI.TEXT_AUTOCAPITALIZATION_NONE,
            keyboardType: Titanium.UI.KEYBOARD_EMAIL,
            returnKeyType: Titanium.UI.RETURNKEY_GO
        }));

        passwordText.addEventListener('return', function() {
            passwordText.blur();
            loginButton.fireEvent('click');
        });
        containerView.add(passwordText);


        // now for our login button!
        var loginButton;
        if (candp.osname === 'iphone') {
            loginButton = Ti.UI.createButton(candp.combine($$.button, {
                bottom: 15,
                left: 50,
                right: 50,
                title: L('login')
            }));                
        } else {
            loginButton = Ti.UI.createButton(candp.combine($$.androidLoginButton, {
                bottom: 15,
                left: 50,
                right: 50,
                title: L('login')
            }));            
        }

        loginButton.addEventListener('click', function(e) {
            loginModel.loginButton(e, emailText.value, passwordText.value);
            Ti.App.fireEvent('app:login.hide');
        });
        containerView.add(loginButton);


        // assemble our view (easy!)
        loginView.add(containerView);

        
        // we're better off putting the event for opening/closing the view here 
        // rather than in the model
        Ti.App.addEventListener('app:login.toggle', function(e) {
            // blur to close the keyboard if it's open
            passwordText.blur();
            emailText.blur();

            switch (candp.osname) {
                case 'android':
                    // *TODO: investiate the problems with Android animations
                    switch(loginView.showing) {
                        case false:
                            loginView.show();
                            loginView.showing = true;
                            break;
                        case true:
                            loginView.hide();
                            loginView.showing = false;
                            break;
                    }
                    break;

                case 'iphone':
		            switch(loginView.visible) {
		                case false:
				            loginView.top = -$$.platformHeight;
				            loginView.show();

		                    candp.view.slide(loginView, 'down', null, null);
		                    break;
		
		                case true:
				            candp.view.slide(loginView, 'up', function() {
		                        loginView.hide();
		                    }, null);
		                    break;
		            }
                    break;
            }
        });
 
        Ti.App.addEventListener('app:login.hide', function(e) {
            passwordText.blur();
            emailText.blur();
            switch (candp.osname) {
                case 'android':
                    // *TODO: investigate the problems with Android animations
                    loginView.hide();
                    loginView.showing = false;
                    break;
                case 'iphone':
	                candp.view.slide(loginView, 'up', function() {
	                    loginView.hide();
	                }, null);
                    break;
            }
        });

        return loginView;
    };
})();
