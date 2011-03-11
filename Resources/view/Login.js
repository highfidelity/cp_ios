/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for login screen.  This is shown as a modal dialog which slides down
 * from the header bar, takes the user's username/password, and initiates a login
 * with the CandP server
 * 
 */

(function() {
    candp.view.createLoginView = function (args) {
        var loginView = Ti.UI.createView(candp.combine($$.stretch, {
            visible: false
        }));

        loginView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
			top: 80,
            text: L('title_login')
        })));

		// *TODO: Add username label
		// *TODO: Add username text box
		// *TODO: Add password label
		// *TODO: Add password text box
		// *TODO: Add login button
		// *TODO: Find out if we require a "forgot password" link

        return loginView;
    };
})();