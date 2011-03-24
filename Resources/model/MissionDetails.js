/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for the user profile.  Any complex logic for user profile lives here
 * 
 */

var missionDetailsModel = {};

(function() {
    missionDetailsModel.getMissionById = function(e, callback) {
        candp.model.xhr(
            candp.config.apiUrl,
            'POST',
            {
                action: 'missiondetail',
                id: e.id
            }, 
            function(e) {
                var response = JSON.parse(e.response);
                if (response.payload) {
                    response.payload.author_id = response.payload.author.id;
                    response.payload.photo = response.payload.author.photo;
                    callback(response.payload);
                }
            }
        );        
    };

    missionDetailsModel.makeOffer = function(e, callback) {
        var offerTitle = e.offerTitle;
        var offerAmount = e.offerAmount;
        var receiverUserId = e.receiverUserId;
        var missionId = e.missionId;
        var payMe = e.payMe;

        candp.model.xhr(
            candp.config.offersUrl,
            'POST',
            {
                action: 'makeOffer',
                title: offerTitle,
                amount: offerAmount,
                receiver_user_id: receiverUserId,
                mission_id: missionId,
                pay_me: payMe
            },
            function(e) {
                // we've pushed an offer to the server for this mission
                var response = JSON.parse(e.response);
                callback(response);
            }
        );
    };

})();