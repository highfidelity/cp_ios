/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author Hans
 * 
 * @brief Model for the users table.  Any complex logic for users lives here
 * 
 */

var usersModel = {};

(function() {
    usersModel.getUsersList = function(e) {
    };

    usersModel.getUsersList = function(e, callback) {
        // go grab our current position
        candp.model.xhr(
            candp.config.apiUrl,
            'POST',
            {
                action: 'userlist',  
                lat: candp.location.latitude, 
                lon: candp.location.longitude
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                if (response.payload) {
                    callback(response.payload);
                }
            }
        );
    };
})();
