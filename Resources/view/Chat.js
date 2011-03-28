/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for 1 on 1 chat
 * 
 */

(function() {
    candp.view.createChatView = function (args) {
        var chatView = Ti.UI.createView(candp.combine($$.contained, {
            backgroundImage: 'images/transparent.png',
            visible: false
        }));

/*
        chatView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            top: 20,
            text: "TESTING FOR CHAT"
        })));

        
        chatView.addEventListener('click', function(e) {
            chatModel.sendChatMessage(196, 'This time, sponsored by SHS, is ' + new Date(), function(e) {
                Ti.API.info('We sent a message to 196, and we got back ' + e.response);

            });

            setTimeout(10000, getWaitingMessages());
        });
*/
        var url = 'http://www.coffeeandpower.com/chat/index1to1.php?receiving_user_id=196&PHPSESSID=' + candp.sessionId; 
        Ti.API.info('url is ' + url);
        var webView = Ti.UI.createWebView({
            url: url,
            scalesPageToFit: false
        });
        chatView.add(webView);

/*
        function getWaitingMessages() {
            chatModel.getWaitingMessage(function(e) {
                Ti.API.info('GET WAITING MESSAGES RESPONDED WITH ...>>>' + e.response);
                setTimeout(10000, getWaitingMessages());
            });
        }
*/
        Ti.App.addEventListener('app:chat.refreshUrl', function(e) {
            webView.url = 'http://www.coffeeandpower.com/chat/index1to1.php?receiving_user_id=196&PHPSESSID=' + candp.sessionId;
            Ti.API.info('webview.url = ' + webView.url);
            webView.reload();
        });
	
        return chatView;
    };
})();
