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
    Date.prototype.toRelativeTime = function(now_threshold) {
        var delta = new Date() - this;

        now_threshold = parseInt(now_threshold, 10);       
        if (isNaN(now_threshold)) {
            now_threshold = 0;
        }
       
        if (delta <= now_threshold) {
            return L('just_now');
        }
       
        var units = null;
        var conversions = {
            millisecond: 1, // ms    -> ms
            second: 1000,   // ms    -> sec
            minute: 60,     // sec   -> min
            hour: 60,     // min   -> hour
            day: 24,     // hour  -> day
            month: 30,     // day   -> month (roughly)
            year: 12      // month -> year
        };
       
        for (var key in conversions) {
            if (delta < conversions[key]) {
                break;
            } else {
                units = key; // keeps track of the selected key over the iteration
                delta = delta / conversions[key];
            }
        }
       
        // pluralize a unit when the difference is greater than 1.
        delta = Math.floor(delta);
        if (delta !== 1) { 
            units += "s"; 
        }
        return [L('last_updated'), delta, units, L('ago')].join(' ');
    };



    candp.view.createMissionListView = function (args) {
        var data = [];
        var missions_data = [];
        var lastUpdated;

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


        var headerLabel = Ti.UI.createLabel({
            backgroundImage: 'images/header_bg.png',
            color: '#FFFFFF',
            font: { 
                fontSize: 16, 
                fontWeight: 'bold' 
            },
            text: '',
            textAlign: 'center',
            height: 44,
            width: $$.platformWidth
        });

        var tableView = Ti.UI.createTableView(candp.combine($$.tableView, {
            top: 50,
            left: 0,
            right: 0,
            bottom: 50,
            headerView: headerLabel,
            data: data
        }));
        tableView.addEventListener('click', function(e) {
            // There's a naming clash on mission.type because Titanium framework adds a 'type' 
            // property to describe the type of object that sent the event
            missions_data[e.index].mission_type = missions_data[e.index].type;
            Ti.App.fireEvent('app:missionDetail.show', missions_data[e.index]);
            Ti.App.fireEvent('headerBar:backButton.show', {
                destinationView: 'missionList',
                destinationIndex: 2
            });
        });


        missionListView.add(tableView);


        Ti.App.addEventListener('app:missionList.getMissions', function(e) {
            lastUpdated = new Date();

            missionsModel.getMissionList(e, function(missions) {
                data = [];
                missions_data = missions;

                // fill in the table with missions
                for (var mission in missions) {
                    if (missions.hasOwnProperty(mission)) {
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
    						text: (missions[mission].type === 'want') ? L('i_want') + ' ' + missions[mission].title : L('i_will') + ' ' + missions[mission].title
                        });
                        row.add(missionTitle);
    
                        var formattedTimeDiff = formatTimeDiff(missions[mission].time_diff);
                        missions_data[mission].formattedTimeDiff = formattedTimeDiff;
                        var missionExpires = Ti.UI.createLabel({
    						color:'#333399',
    						font:{fontSize:12, fontFamily:'Arial-ItalicMT'},
    						left:10,
    						bottom:4,
    						height:20,
    						width: 'auto',
    						clickName:'missionExpires',
    						text: (formattedTimeDiff === '0 min') ? L('overdue') : (formattedTimeDiff === '-1 min') ? L('never_expires') : L('expires_in') + ' ' + formattedTimeDiff
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
                }
                headerLabel.text = lastUpdated.toRelativeTime(60000);
                tableView.setData(data);
            });
        });

        function _setHeaderLabel() {
            headerLabel.text = lastUpdated.toRelativeTime(60000);
            setTimeout(_setHeaderLabel, 30000);
        }

        setTimeout(_setHeaderLabel, 30000);

        return missionListView;
    };
})();
