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
        usersModel.getGPS(function(e) {
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
        });
    };

    usersModel.getGPS = function(callback) {
        // get our last known good GPS location -- by default we use a location in San Francisco
        candp.location = JSON.parse(Ti.App.Properties.getString('location', JSON.stringify({latitude: 37.792083, longitude: -122.409196})));
        if (candp.location === {}) {
            candp.location = {
                latitude: 37.792083, 
                longitude: -122.409196
            };
        }

        Ti.Geolocation.purpose = "Coffee and Power Missions List";
        Ti.Geolocation.preferredProvider = Titanium.Geolocation.PROVIDER_GPS;

        // do we have GPS turned on?
        if (Ti.Geolocation.locationServicesEnabled == false) {
            candp.view.alert(L('error'), L('GPS_turned_off'));
            callback(null);
        } else {
            // ok, so grab a 'close enough' location
            Ti.Geolocation.accuracy = Ti.Geolocation.ACCURACY_HUNDRED_METERS;
            Ti.Geolocation.distanceFilter = 50;

            Ti.Geolocation.getCurrentPosition(function(e) {
                if (e.error) {
                    candp.view.alert(L('error'), L('GPS_turned_off'));
                    callback(e);
                } else {
                    candp.location = {
                        latitude: e.coords.latitude,
                        longitude: e.coords.longitude
                    };
        
                    Ti.App.Properties.setString('location', JSON.stringify(candp.location));
                    Ti.API.info('candp.location = ' + JSON.stringify(candp.location));

                    // send an update to the server of our current location
                    Ti.App.fireEvent('app:applicationWindow.setLocation', candp.location);

                    callback(e);
                }
            });
        }
    };


})();
