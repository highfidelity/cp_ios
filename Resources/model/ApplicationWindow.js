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

    applicationModel.setLocation = function(e) {
       candp.model.xhr(
           candp.config.actionServerUrl,
           'POST',
           {
               action: 'setUserLocation',
               lat: e.latitude,
               'long': e.longitude
           },
           function(e) {
               var params = JSON.parse(e.response).params;
           }
       );
    };

    applicationModel.registerDeviceToken = function(deviceToken, callback) {
        candp.model.xhr(
           candp.config.registerAPNTokenUrl,
           'POST',
           {
               APNToken: deviceToken
           },
           function(e) {
               callback(e.response);
           }
        );
    };

    applicationModel.registerForPushNotifications = function(e) {
        Titanium.Network.registerForPushNotifications({
            types: [
                Titanium.Network.NOTIFICATION_TYPE_BADGE,
                Titanium.Network.NOTIFICATION_TYPE_ALERT,
                Titanium.Network.NOTIFICATION_TYPE_SOUND
            ],

            success: function(e) {
                // send the deviceToken to the candp server
                applicationModel.registerDeviceToken(e.deviceToken, function(e) {
                });
            },

            error: function(e) {
                // oops, we don't have push notifications enabled
                candp.view.alert(L('error'), L('error_push_notifications_disabled'));
            },

            callback: function(e) {
                // we've received a push notification from the server
                // so open up the mision details screen
                Ti.App.fireEvent('app:missionDetail.getById', {
                    id: e.data.payload.mission_id
                });
                Ti.App.fireEvent('headerBar:backButton.show', {
                    destinationView: 'missionList',
                    destinationIndex: 2
                });
                
            }

        });
    };

})();
