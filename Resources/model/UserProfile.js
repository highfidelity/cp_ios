/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for the user profile.  Any complex logic for user profile lives here
 * 
 */

var userProfileModel = {};

(function() {
    userProfileModel.getUserProfile = function(e, callback) {
        candp.model.xhr(
            candp.config.actionServerUrl,
            'POST',
            {
                // *FIXME: use the profile id as passed in
                action: 'getUserData',
                user_id: 78 // this is H :-)
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                if (response.params.userData) {
                    Ti.API.info(e.response);
                    callback(response.params.userData);
                }
            }
        );
    };

    userProfileModel.getUserImage = function(e, callback) {
        candp.model.xhr(
            candp.config.actionServerUrl,
            'POST',
            {
                action: 'getPhotoFileWithId',
                photo: e.image_id
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                if (response.params && response.succeeded === true) {
                    callback(response.params);
                }
            }
        );
    };


})();