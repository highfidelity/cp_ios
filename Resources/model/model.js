/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Top level model framework
 * 
 */

(function() {
    candp.model = {};
    
    candp.model.xhr = function(url, method, payload, callback) {
        // helper function for getting the PHP session Id cookie
        function _getPHPSESSID(cookie) {
            var cookieTokens = cookie.split(';');
            return cookieTokens[0].split('PHPSESSID=')[1];
        }

        // We're going to be calling out over the network
        // so make sure we test first (as per Apple's preferred style)
        if (Ti.Network.online === false) {
            candp.view.alert(L('error'), L('error_network_request'));
        } else {
            // ok, so we're connected.  Let's make our network call ...
            // network call might be a long running action, so show the spinner
            Ti.App.fireEvent('app:spinner.show');

            var xhr = Ti.Network.createHTTPClient();
    
            xhr.onload = function(e) {
                // we want to store any session cookie we get back ...
                var sessionCookie = this.getResponseHeader('Set-Cookie');
                if (sessionCookie) {
                    candp.sessionId = _getPHPSESSID(sessionCookie);
                    Ti.App.Properties.setString('sessionId', candp.sessionId);
                }

                // finally trigger the callback
                callback({response: this.responseText, sessionId: candp.sessionId, status: this.status});
                Ti.App.fireEvent('app:spinner.hide');
            };
    
            xhr.onerror = function(e) {
                callback({response: this.error, status: this.status});
                Ti.App.fireEvent('app:spinner.hide');
            };
    
            xhr.open(method, url);
    
            // send a cookie if we have one
            if (candp.sessionId !== '') {
                xhr.setRequestHeader('Cookie', 'PHPSESSID=' + candp.sessionId);
            }

            xhr.send(payload);
        }
    };

    candp.model.isUndefined = function(value) {
        return (value == null && value !== null);
    };

    candp.model.validateNotEmpty = function(value) {
        return (!candp.model.isUndefined(value) && value.length != 0);
    };

    candp.model.validateInput = function(value, validationType) {
        switch(validationType) {
            case candp.config.validationPositiveNumeric:
                return !(isNaN(value) || value <= 0.0);
                break;
            default:
                return false;
        }
    };

})();

Ti.include(
    '/model/ApplicationWindow.js',
    '/model/HeaderBar.js',
    '/model/Login.js',
    '/model/MissionList.js',
    '/model/UserProfile.js',
    '/model/UserList.js',
    '/model/MissionDetails.js'
);
