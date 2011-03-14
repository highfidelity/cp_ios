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
        missionListView.add(tableView);


        candp.model.xhr(
            candp.config.missionsUrl,
            'POST',
            {
                // *FIXME: use the gps to get the real position
                action: 'getMissions',  
                sw_lat: 37.757144, 
                sw_lng: -122.44606,
                ne_lat: 37.807885,
                ne_lng: -122.408981,
                SkillsIDList: ''
            }, 
            function(e) {
                Ti.API.info('response = ' + e.response);
                var response = JSON.parse(e.response);
                if (response.params.listOfMissions) {
                    deadline0 = response.params.listOfMissions[0].deadline;
                    deadline1 = response.params.listOfMissions[1].deadline;
                    Ti.API.info('date0 = ' + deadline0);
                    Ti.API.info('date1 = ' + deadline1);
                    Ti.API.info('date0 > date1 = ' + (deadline0 > deadline1));
                    Ti.API.info('date0 < date1 = ' + (deadline0 < deadline1));

                    for (var mission in response.params.listOfMissions) {
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
							text: response.params.listOfMissions[mission].title
                        });
                        row.add(missionTitle);


                        var formattedTimeDiff = formatTimeDiff(response.params.listOfMissions[mission].time_diff);
                        var missionExpires = Ti.UI.createLabel({
							color:'#333399',
							font:{fontSize:12, fontFamily:'Arial-ItalicMT'},
							left:10,
							bottom:4,
							height:20,
							width: 'auto',
							clickName:'missionExpires',
							text: formattedTimeDiff == '0 min' ? 'overdue' : 'expires in ' + formattedTimeDiff
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
							text: parseFloat(response.params.listOfMissions[mission].distance).toFixed(1) + ' miles'
                        });
                        row.add(missionDistance);



                        data.push(row);
                    }

                    tableView.setData(data);

                }
            }
        );


        // *TODO: Add eventListener that opens up the individual mission detail view

        return missionListView;
    };
})();
