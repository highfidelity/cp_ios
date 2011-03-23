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
        var offerTitle = e.offerTitle;
        var offerAmount = e.offerAmount;
        var receiverUserId = e.receiverUserId;
        var missionId = e.missionId;
        var payMe = e.payMe;

        candp.model.xhr(
            candp.config.offersUrl,
            'POST',
            {
                action: 'getView',
                receiver_user_id: receiverUserId,
                already_created: 'N',
                offer_id: '',
                mission_id: missionId
            },
            function(e) {
                Ti.API.info('Offer_id request got a response of ' + JSON.stringify(e));
                // *FIXME: make sure we handle the situation of 
                // response: ... This mission in 'Underway' status. Can't add more offers!'
                
                // we've now got an offer id
                missionDetailsModel.offer_id = e.response.split('data-offer-id="')[1].split('"')[0];
                missionDetailsModel.finaliseOffer({
                    offerId: e.response.split('data-offer-id="')[1].split('"')[0],
                    title: offerTitle,
                    amount: offerAmount,
                    receiverUserId: receiverUserId,
                    missionId: missionId,
                    payMe: payMe
                }, function(e) {
                    callback(e);
                });
            }
        );
    };

    missionDetailsModel.finaliseOffer = function(e, callback) {
        candp.model.xhr(
            candp.config.offersUrl,
            'POST',
            {
                action: 'makeOffer',
                title: e.title,
                amount: e.amount,
                receiver_user_id: e.receiverUserId,
                offer_id: e.offerId,
                mission_id: e.missionId,
                pay_me: e.payMe
            },
            function(e) {
                // we've pushed an offer to the server for this mission
                callback(e.response);
            }
        );
    };

})();