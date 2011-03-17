/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
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

    // function for sliding a view
    candp.view.slide = function(view, slideDirection, complete, start) {
        var m;

        // helper function
        function _createAnimation(m, callback) {
            var a;
			a = Ti.UI.createAnimation();
			a.duration = 500; 
			a.transform = m;
		    if (typeof callback === 'function') {
			    a.addEventListener('complete', complete);
		    }
		    if (typeof start === 'function') {
			    a.addEventListener('start', start);
		    }
            return a;
        }

        switch(slideDirection) {
            case 'up':
            	m = Ti.UI.create2DMatrix().translate(0, -($$.platformHeight + candp.config.headerHeight)); 
		        view.animate(_createAnimation(m, complete, start));
                break;

            case 'down':
            	m = Ti.UI.create2DMatrix().translate(0, $$.platformHeight + candp.config.headerHeight); 	
		        view.animate(_createAnimation(m, complete, start));
                break;

            case 'left':
            	m = Ti.UI.create2DMatrix().translate(-$$.platformWidth, 0); 	
		        view.animate(_createAnimation(m, complete, start));
                break;

            case 'right':
            	m = Ti.UI.create2DMatrix().translate($$.platformWidth, 0); 	
		        view.animate(_createAnimation(m, complete, start));
                break;

            case 'leftslide':
                m = Ti.UI.createAnimation();
                m.duration = 500;
                m.left = -Ti.Platform.displayCaps.platformWidth;
                view.animate(m);
        }
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
