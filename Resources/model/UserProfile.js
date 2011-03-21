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
    userProfileModel.last_user_id = 69;

    userProfileModel.getUserProfile = function(e, callback) {
        userProfileModel.last_user_id = e.user_id;
        candp.model.xhr(
            candp.config.apiUrl,
            'POST',
            {
                // *FIXME: use the profile id as passed in
                action: 'userdetail',
                id:  e.user_id || userProfileModel.last_user_id
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                if (response.payload) {
                    Ti.API.info(e.response);
                    callback(response.payload);
                }
            }
        );
    };

    userProfileModel.getUserImage = function(e, callback) {
        if (e.image_id == 0) {
            callback('images/no_picture.jpg');
        } else {
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
                        callback(candp.config.baseUrl + response.params);
                    }
                }
            );
        }
    };


    userProfileModel.makeOffer = function(e, callback) {
        candp.model.xhr(
            candp.config.offersUrl,
            'POST',
            {
                action: 'makeOffer',
                title: 'an offer title .. made from the iphone app',
                amount: 1,
                receiver_user_id: 196,
                offer_id: 556,
                mission_id: 341,
                pay_me: 1
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                callback(response);
            }
        );
    };

})();