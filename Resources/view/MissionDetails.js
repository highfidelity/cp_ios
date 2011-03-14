/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for the mission details.  This view gives more detailed information
 * regarding a particular mission.  From here, the user is able to chat with the 
 * mission creator, view the profile of the mission creator, or make an offer to
 * carry out the mission
 * 
 */

(function() {
    candp.view.createMissionDetailsView = function (args) {
        var missionDetailsView = Ti.UI.createView(candp.combine($$.stretch, {
            backgroundColor: '#FFFFFF',
            visible: false
        }));

        missionDetailsView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            top: 80,
            color: '#000000',
            text: L('title_missiondetails')
        })));

        // *TODO: Add mission detail title label
        // *TODO: Add mission detail label
        // *TODO: Add mission detail due date label
        // *TODO: Add mission detail due date as words label
        // *TODO: Add mission detail posted by image
        // *TODO: Add mission detail posted by label
        // *TODO: Add mission detail user profile button (arrow)
        // *TODO: Add mission detail make offer button
        // *TODO: Add mission detail initiate 1:1 chat button
        // *TODO: Add event listener for make offer button
        // *TODO: Add event listener for initiate 1:1 chat button

        return missionDetailsView;
    };
})();
