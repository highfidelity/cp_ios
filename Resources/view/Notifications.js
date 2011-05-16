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
		Titanium.API.log('Creating notifications view!');

		var data = [{
			title: L('loading_missions')
		}
		];

		var missions_data = [];
		var lastUpdated;
		var getLastUpdatedIntervalId;

		function formatTimeDiff(secs) {
			var hours = Math.floor(secs / (60 * 60));
			var divisor_for_minutes = secs % (60 * 60);
			var minutes = Math.floor(divisor_for_minutes / 60);
			var returnString = '';
			// *TODO: convert the hr/min/s to i18n strings
			if (hours > 0) {
				returnString = hours + ' hr' + (hours > 1 ? 's' : '') + ', ';
			}
			returnString += minutes + ' min' + (minutes > 1 ? 's' : '');
			return returnString;
		};

		var notificationListView = Ti.UI.createView(candp.combine($$.stretch, {
			visible: false
		}));

		// let's have a label that shows us when we last collected data
		var headerLabel = Ti.UI.createLabel({
			backgroundImage: 'images/header_bg.png',
			color: '#FFFFFF',
			font: {
				fontSize: 16,
				fontWeight: 'bold'
			},
			text: L('my_missions'),
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
				destinationView: 'notifications',
				destinationIndex: 2
			});
		});
		notificationListView.add(tableView);

		Ti.App.addEventListener('app:notificationsList.getMissions', function(e) {
			lastUpdated = new Date();

			Titanium.API.log('Notifications event added');

			notificationsModel.getNotificationsList(e, function(missions) {
				if(missions == null) {
					data = [];
					var row = Ti.UI.createTableViewRow(candp.combine($$.tableViewRow, {
						height: 60,
						hasChild: true
					}));
					var missionTitle = Ti.UI.createLabel({
						color:'#333333',
						font: {
							fontSize:20,
							fontWeight:'bold',
							fontFamily:'Arial'
						},
						left:10,
						top:5,
						height: 25,
						right:50,
						clickName:'notLogged',
						text: 'Not logged in'
					});
					row.add(missionTitle);
					data.push(row);
					
					Titanium.API.log('CURRENT VIEW: ' + candp.view.currentActiveView);
					
					if(candp.view.currentActiveView == 'notifications')
					   Ti.App.fireEvent('app:login.toggle');
				} else {
					data = [];
					missions_data = missions;

					Titanium.API.log('Getting missions: ' + missions);

					// fill in the table with missions
					for (var mission in missions) {
						if (missions.hasOwnProperty(mission)) {
							var row = Ti.UI.createTableViewRow(candp.combine($$.tableViewRow, {
								height: 60,
								hasChild: true
							}));

							var missionTitle = Ti.UI.createLabel({
								color:'#333333',
								font: {
									fontSize:17,
									fontWeight:'bold',
									fontFamily:'Arial'
								},
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

							var aux =  missions[mission].status;
							var aux_color = '#044c24';
							if(aux == 'Available') {
								aux = "Offers: " + parseFloat(missions[mission].offers_count);
								aux_color = '#333399';
							}

							var missionOffers = Ti.UI.createLabel({
								color: aux_color,
								font: {
									fontSize:15,
									fontFamily:'Arial'
								},
								right:10,
								bottom:4,
								height:20,
								width: 'auto',
								clickName:'missionOffers',
								text: aux
							});
							row.add(missionOffers);

							data.push(row);
						}
					}
				}

				// helper function for the iphone interval to update the header
				function _setHeaderLabel() {
					headerLabel.text = L('my_missions');
					lastUpdated.toRelativeTime(60000);
				}

				candp.os({
					android: function() {
						lastUpdated = new Date();
						// *TODO: use string interpolation (rather than concatenation) with the i18n string
						headerLabel.text = L('last_collected_at') + ' ' + lastUpdated.toLocaleTimeString();
					},
					iphone: function() {
						_setHeaderLabel();
						setInterval(_setHeaderLabel, candp.config.getLastUpdatedTime);
					}
				});

				tableView.setData(data);
			});
		});
		return notificationListView;
	};
})();