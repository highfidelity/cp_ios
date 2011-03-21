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

        chatView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            top: 20,
            text: "TESTING FOR CHAT"
        })));


        chatView.addEventListener('click', function(e) {
            // get the csrf_token
            chatModel.chatLogin(e, function(csrf_token) {
                candp.view.alert('we connected ..', csrf_token);
            });
        });

	
        return chatView;
    };
})();
