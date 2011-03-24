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
    chatModel.lastid = null;
    chatModel.lasttouched = null;
    chatModel.lastprivate = null;
    chatModel.sampled = null;

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
                callback(e);
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

	chatModel.sendChatMessage = function(recipient_id, message, callback) {
        candp.model.xhr(
            candp.config.chatUrl,
            'POST',
            {
                what: 'send',
                message: message,
                tries: 1,
                lastid: chatModel.lastid,
                lasttouched: chatModel.lasttouched,
                filter: null,
                last_private: chatModel.lastprivate,
                csrf_token: chatModel.csrf_token,
                sampled: chatModel.sampled,
                receiving_user_id: recipient_id,
                entry_lat: candp.location.latitude,
                entry_lng: candp.location.longitude,
                entry_skills_id: null,
                sw_lat: candp.location.latitude - 0.1,
                sw_lng: candp.location.longitude - 0.1,
                ne_lat: candp.location.latitude + 0.1,
                ne_lng: candp.location.longitude + 0.1
            },
            function(e) {
                var response = JSON.parse(e.response);
                chatModel.lastid = response.lastId;
                chatModel.lasttouched = response.lasttouched;
                chatModel.lastprivate = response.last_private;
                chatModel.sampled = response.newentries[0].sampled;

                // *TODO: what do we do about
                //    parent.CandpSocket.notifyChat1to1(journal.receiving_user_id, retryMessage);

                callback(e);
            }
        );
    };

    chatModel.getWaitingMessage = function(callback) {
        candp.model.xhr(
            candp.config.chatUrl,
            'POST',
            {
                what: 'latest_longpoll',
                opt: '1', //'3', //'1',
                timeout: 5,
                lastid: chatModel.lastid,
                lasttouched: chatModel.lasttouched,
                csrf_token: chatModel.csrf_token,
                filter: null,
                last_private: chatModel.lastprivate,
                receiving_user_id: 196, // 1329, // 196,
                sw_lat: candp.location.latitude - 0.1,
                sw_lng: candp.location.longitude - 0.1,
                ne_lat: candp.location.latitude + 0.1,
                ne_lng: candp.location.longitude + 0.1,
                entry_skill_ids: null
            },
            function(e) {
                var response = JSON.parse(e.response);
                chatModel.lasttouched = response.lasttouched;
                callback(e);
            }
        );
    };

})();