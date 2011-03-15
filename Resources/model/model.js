/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Top level model framework
 * 
 */

(function() {
    candp.model = {
        dbname: 'candp'
    };
    
    candp.model.xhr = function(url, method, payload, callback) {

        // helper function for getting the PHP session Id cookie
        function _getPHPSESSID(cookie) {
            var cookieTokens = cookie.split(';');
            return cookieTokens[0].split('PHPSESSID=')[1];
        }

        // We're going to be calling out over the network
        // so make sure we test first (as per Apple's preferred style)
        // *FIXME: erm, how about we do that test then, eh? :-)
        var xhr = Ti.Network.createHTTPClient();

        xhr.onload = function(e) {
            // we want to store any session cookie we get back ...
            var sessionCookie = this.getResponseHeader('Set-Cookie');
            if (sessionCookie) {
                candp.sessionId = _getPHPSESSID(sessionCookie);
                Ti.App.Properties.setString('sessionId', candp.sessionId);
                Ti.API.info('New session id received = ' + candp.sessionId);
            }

            // finally trigger the callback
            callback({response: this.responseText, sessionId: candp.sessionId, status: this.status});
        };

        xhr.onerror = function(e) {
            callback({response: this.error, status: this.status});
        };

        // *TODO: open an animated spinner as feedback to
        // the user that we're doing something
        xhr.open(method, url);

        // send a cookie if we have one
        if (candp.sessionId !== '') {
            xhr.setRequestHeader('Cookie', 'PHPSESSID=' + candp.sessionId);
        }
        xhr.send(payload);
    };


})();

Ti.include(
    '/model/ApplicationWindow.js',
    '/model/HeaderBar.js',
    '/model/Login.js',
    '/model/MissionList.js',
    '/model/UserProfile.js'
);
