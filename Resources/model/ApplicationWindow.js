/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for the main application window.  Mostly startup code runs from here
 * 
 */

var applicationModel = {};

(function() {
    applicationModel.checkLoggedIn = function(e) {
        candp.model.xhr(
            candp.config.actionServerUrl,
            'POST',
            {
                action: 'isLoggedIn'
            },
            function(e) {
                var params = JSON.parse(e.response).params;
                var logged = params.logged;
                
                Ti.API.info('logged = ' + logged);
                if (logged === 'true') {
                    // we're logged in, so change our shown state
                    Ti.App.fireEvent('app:headerBar.changeState', {
                        newState: 'loggedIn'
                    });
                }
            }
        );
    };

})();
