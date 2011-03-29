/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Stub view for Notifications.  This should be a blank page as we don't track 
 * notifications as yet (this is *not* part of MVP)
 * 
 */

(function() {
    candp.view.createNotificationsView = function (args) {
        var notificationsView = Ti.UI.createView(candp.combine($$.contained, {
            backgroundImage: null,
            backgroundColor: '#000000',
            visible: false
        }));

        notificationsView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            text: L('intentionally_blank'),
            top: 50,
            left: 10,
            right: 10,
            height: 50
        })));

        return notificationsView;
    };
})();
