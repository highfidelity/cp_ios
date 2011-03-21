/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for chat.  We put all our complex logic here to keep the view clean
 * 
 */


var chatModel = {};

(function() {
    chatModel.csrf_token = '';

    chatModel.chatLogin = function(e, callback) {         
        var xhr = Ti.Network.createHTTPClient();
        
        xhr.onload = function(e) {
            // *FIXME: this is a delicate piece of code :-( ... if the format of the 
            // chat code changes then the csrf_token code may break.  How else can we 
            // get this?

            var sessionCookie = this.getResponseHeader('Set-Cookie');
            Ti.API.info('CHAT >>> we got back ' + sessionCookie);

            chatModel.csrf_token = this.responseText.split('csrf_token = \'')[1].split('\';')[0];

            // send a heartbeat
            chatModel.sendHeartBeat(function(e) {
                callback(chatModel.csrf_token);
            });
        };
   
        xhr.onerror = function(e) {
            candp.view.alert(this.error);
        };
   
        // make a request out to the chat server to get ourselves registered
        xhr.open('GET', candp.config.chatIndexUrl);
        if (candp.sessionId !== '') {
            xhr.setRequestHeader('Cookie', 'PHPSESSID=' + candp.sessionId);
        }
        xhr.send();
    };


    // this is basically pinging the chat server to say "Hi, I'm here online"
    chatModel.sendHeartBeat = function(callback) {
        candp.model.xhr(
            candp.config.chatUrl,
            'POST',
            {
                what: 'speakeronline',
                csrf_token: chatModel.csrf_token
            }, 
            function(e) {
                callback(e);
            }
        );
    };


	chatModel.sendChatMessage = function(recipient_id, message) {
        
    };

})();