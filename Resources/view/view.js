/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Use the view namespace for all view component creation.  We define a few
 * of the smaller components here, but most have their own definition files
 * (included from here).
 * 
 */

(function() {
    candp.view = {};

    // store all our views for easier access later
    candp.view.views = [];

    // spacer row for a table view
    candp.view.createSpacerRow = function() {
        return Ti.UI.createTableViewRow($$.spacerRow);
    };
	
    // shortcut for alert dialog
    candp.view.alert = function(title, message) {
        Ti.UI.createAlertDialog({
            title: title, 
            message: message,
            buttonNames: [L('ok')]
        }).show();
    };
})();

// include the major view components and styling properties
Ti.include(
    '/view/styles.js',
    '/view/ApplicationWindow.js',
    '/view/MissionList.js',
    '/view/MissionDetails.js',
    '/view/UserProfile.js',
    '/view/Chat.js',
    '/view/Login.js',
    '/view/ButtonBar.js',
    '/view/HeaderBar.js'
);
