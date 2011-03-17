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
                // *FIXME: use the profile id as passed in
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
})();