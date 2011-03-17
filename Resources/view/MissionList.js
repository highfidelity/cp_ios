/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
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

        var data = [];
        var missions_data = [];

	    function formatTimeDiff(secs) {	    
	        var hours = Math.floor(secs / (60 * 60)); 
	        var divisor_for_minutes = secs % (60 * 60);
	        var minutes = Math.floor(divisor_for_minutes / 60);
	        var returnString = '';
	        if (hours > 0) {
	            returnString = hours + ' hr' + (hours > 1 ? 's' : '') + ', ';
	        }
	        returnString += minutes + ' min' + (minutes > 1 ? 's' : '');
	        return returnString;
	    };


        var missionListView = Ti.UI.createView(candp.combine($$.stretch, {
            visible: false
        }));


        var tableView = Ti.UI.createTableView(candp.combine($$.tableView, {
            top: 50,
            left: 0,
            right: 0,
            bottom: 50,
            data: data
        }));
        tableView.addEventListener('click', function(e) {
            Ti.API.info('Row = ' + JSON.stringify(missions_data[e.index]));
            Ti.App.fireEvent('app:missionDetail.show', missions_data[e.index]);
        });


        missionListView.add(tableView);


        Ti.App.addEventListener('app:missionList.getMissions', function(e) {
            missionsModel.getMissionList(e, function(missions) {
                missions_data = missions;

                // fill in the table with missions
                for (var mission in missions) {
                    var row = Ti.UI.createTableViewRow(candp.combine($$.tableViewRow, {
                        height: 60,
                        hasChild: true
                    }));

                    var missionTitle = Ti.UI.createLabel({
						color:'#333333',
						font:{fontSize:16,fontWeight:'bold', fontFamily:'Arial'},
						left:10,
						top:5,
						height: 25,
						right:50,
						clickName:'missionTitle',
						text: missions[mission].title
                    });
                    row.add(missionTitle);

                    var formattedTimeDiff = formatTimeDiff(missions[mission].time_diff);
                    var missionExpires = Ti.UI.createLabel({
						color:'#333399',
						font:{fontSize:12, fontFamily:'Arial-ItalicMT'},
						left:10,
						bottom:4,
						height:20,
						width: 'auto',
						clickName:'missionExpires',
						text: formattedTimeDiff == '0 min' ? L('overdue') : L('expires_in') + ' ' + formattedTimeDiff
                    });
                    row.add(missionExpires);


                    var missionDistance = Ti.UI.createLabel({
						color:'#333399',
						font:{fontSize:12, fontFamily:'Arial'},
						right:10,
						bottom:4,
						height:20,
						width: 'auto',
						clickName:'missionDistance',
						text: parseFloat(missions[mission].distance).toFixed(1) + ' ' + L('miles')
                    });

                    row.add(missionDistance);
                    data.push(row);
                }
                tableView.setData(data);
            });
        });

        // *TODO: Add eventListener that opens up the individual mission detail view

        return missionListView;
    };
})();
