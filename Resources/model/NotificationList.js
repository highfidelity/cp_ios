/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for the missions table.  Any complex logic for missions lives here
 * 
 */

var notificationsModel = {};

(function() {
    notificationsModel.getNotificationsList = function(e, callback) {
        // go grab our current position
        candp.model.xhr(
            candp.config.missionsUrl,
            'POST',
            {
                action: 'getMyMissionsJSON'
            }, 
            function(e) {
                //Titanium.API.log('Received: ' + e.response);
                var response = JSON.parse(e.response);
                if(response.params == null){
                	callback(null);
                } else if (response.params.listOfMissions) {
                    callback(response.params.listOfMissions);
                }
            }
        );
    };
})();
