/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for 1 on 1 chat
 * 
 */

(function() {
    candp.view.createChatView = function (args) {
        var chatView = Ti.UI.createView(candp.combine($$.stretch, {
            visible: false
        }));

        chatView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
			top: 80,
            text: L('title_chat')
        })));

        return chatView;
    };
})();