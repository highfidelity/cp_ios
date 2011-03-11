/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for the missions table.  Once connected to the CandP server, the 
 * user sees a table of missions that are within the user's vicinity.  Clicking 
 * on a mission row opens the mission detail view.
 * 
 */

(function() {
    candp.view.createMissionListView = function (args) {
        var missionListView = Ti.UI.createView(candp.combine($$.stretch, {
            visible: false
        }));

        missionListView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            top: 80,
            text: L('title_missionlist')
        })));

		// *TODO: Add a table view
		// *TODO: Add eventListener that opens up the individual mission detail view

        return missionListView;
    };
})();