/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for login dialog.  We put all our complex logic here to keep the view clean
 * 
 */


var loginModel = {};

(function() {
    loginModel.loginButton = function(e, username, password) {
        candp.model.xhr(
            candp.config.loginUrl,
            'POST',
            {
                action: 'login',
                username: username,
                password: password
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                if (response.params) {
                    // we have successfully logged in
	                Ti.App.fireEvent('app:headerBar.changeState', {
	                    newState: 'loggedIn'
	                });

                    // save the details for future
                    Ti.App.Properties.setString('username', username);
                } else {
                    // let's be nice to the user and allow them to
                    // re-try their login
                    setTimeout(function() {
                        Ti.App.fireEvent('app:login.toggle');
                    }, 1000);
                    candp.view.alert(L('error'), response.message);
                }
            }
        );
    };

})();
