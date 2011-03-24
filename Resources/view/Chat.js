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
            chatModel.sendChatMessage(196, 'This time, sponsored by SHS, is ' + new Date(), function(e) {
                Ti.API.info('We sent a message to 196, and we got back ' + e.response);

            });

            setTimeout(10000, getWaitingMessages());
        });


        function getWaitingMessages() {
            chatModel.getWaitingMessage(function(e) {
                Ti.API.info('GET WAITING MESSAGES RESPONDED WITH ...>>>' + e.response);
                setTimeout(10000, getWaitingMessages());
            });
        }

        
	
        return chatView;
    };
})();
