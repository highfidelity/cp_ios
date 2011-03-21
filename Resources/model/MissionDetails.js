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
    missionDetailsModel.getMissionDetail = function(e, callback) {
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
                    Ti.API.info(e.response);
                    callback(response.payload);
                }
            }
        );        
    };

    missionDetailsModel.makeOffer = function(e, callback) {
        candp.model.xhr(
            candp.config.offersUrl,
            'POST',
            {
                action: 'getView',
                receiver_user_id: 196,
                already_created: 'N',
                offer_id: '',
                mission_id: 341
            },
            function(e) {
                // we've now got an offer id
                missionDetailsModel.offer_id = e.response.split('data-offer-id="')[1].split('"')[0];
                missionDetailsModel.finaliseOffer({
                    offer_id: e.response.split('data-offer-id="')[1].split('"')[0]
                }, function(e) {
                    callback(e);
                });
            }
        );
    };

    missionDetailsModel.finaliseOffer = function(e, callback) {
        var now = new Date();
        candp.model.xhr(
            candp.config.offersUrl,
            'POST',
            {
                action: 'makeOffer',
                title: 'an offer title .. made from the iphone app' + now,
                amount: 1,
                receiver_user_id: 196,
                offer_id: e.offer_id,
                mission_id: 341,
                pay_me: 1
            },
            function(e) {
                // we've pushed an offer to the server for this mission
                callback(e.response);
            }
        );
    };

})();