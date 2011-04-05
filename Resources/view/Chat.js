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
        // set up a NOP nextAction function for later use
        var nextAction = function(e) {
        };

        var chatView = Ti.UI.createView(candp.combine($$.contained, {
            backgroundImage: 'images/transparent.png',
            visible: false
        }));
/*
        var url = candp.config.chatIndexUrl;
        var webView = Ti.UI.createWebView({
            url: url,
            scalesPageToFit: false
        });
        chatView.add(webView);


        webView.addEventListener('load', function(e) {
            // every time we load a page, we want to call the next action in the sequence
            nextAction();
        });

      
        Ti.App.addEventListener('app:chat.initiateChat', function(e) {
            Ti.App.fireEvent('app:spinner.show');

            var userId = e.userId;
            var username = Ti.App.Properties.getString('username');
            var password = Ti.App.Properties.getString('password');
            var url = candp.config.loginUrl + '?action=login&username=' + username + '&password=' + password;
            nextAction = function(e) {
                Ti.App.fireEvent('app:chat.refreshUrl', {userId: userId});
            };

            webView.visible = false;
            webView.url = url;
        });


        Ti.App.addEventListener('app:chat.refreshUrl', function(e) {
            // clear out the next action
            nextAction = function(e) {
                webView.visible = true;
                Ti.App.fireEvent('app:spinner.hide');
            };

            // and open the 1:1 chat with the other user
            webView.url = candp.config.chatUrl + '?receiving_user_id=' + e.userId;
        });


        Ti.App.addEventListener('app:chat.loadGroupChat', function(e) {
            nextAction = function(e) {
                webView.visible = true;
                Ti.App.fireEvent('app:spinner.hide');
            };

            // open the group chat url
            webView.url = candp.config.chatIndexUrl;
        });
*/	
        return chatView;
    };
})();
