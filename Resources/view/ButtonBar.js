/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for the button bar at the bottom of the main screen.  Rather
 * than use the standard Titanium tab layout, we use our own button bar so
 * that we can have the same layout in both Android and iPhone
 * 
 */

(function() {
    candp.view.createButtonBarView = function (args) {
		// helper function
		function _fireEvent(nextViewToShow, clickedButtonIndex, previousButtonIndex) {
            Ti.App.fireEvent('app:buttonBar.click', {
				nextViewToShow: nextViewToShow, 
				clickedButtonIndex: clickedButtonIndex,
				previousButtonIndex: previousButtonIndex
			});
		}

        // what buttons do we want on our button bar?
        var buttons = [
            {
                title: L('buttonbar_public_chat'),
                imageOff: 'images/buttonbar_chat_off.png',
                imageOn: 'images/buttonbar_chat_on.png',
                onClick: function(clickedButtonIndex, previousButtonIndex) {
					// *FIXME: one on one chat for testing, but it ought to be public chat
					// however, we'll need a stub created as this isn't MVP
                    _fireEvent('chat', clickedButtonIndex, previousButtonIndex);
                }
            },
            {
                title: L('buttonbar_people'),
                imageOff: 'images/buttonbar_people_off.png',
                imageOn: 'images/buttonbar_people_on.png',
                onClick: function(clickedButtonIndex, previousButtonIndex) {
					// *FIXME: mission details  for testing, but it ought to be people
					// however, we'll need a stub created as this isn't MVP
                    _fireEvent('missionDetails', clickedButtonIndex, previousButtonIndex);
                }
            },
            {
                title: L('buttonbar_missions'),
                imageOff: 'images/buttonbar_missions_off.png',
                imageOn: 'images/buttonbar_missions_on.png',
				on: true,
                onClick: function(clickedButtonIndex, previousButtonIndex) {
                    _fireEvent('missionList', clickedButtonIndex, previousButtonIndex);
                }
            },
            {
                title: L('buttonbar_notifications'),
                imageOff: 'images/buttonbar_notifications_off.png',
                imageOn: 'images/buttonbar_notifications_on.png',
                onClick: function(clickedButtonIndex, previousButtonIndex) {
					// *FIXME: login for testing, but it ought to be notifications
					// however, we'll need a stub created as this isn't MVP (must check this with Ryan)
                    _fireEvent('login', clickedButtonIndex, previousButtonIndex);
                }
            }
        ];

        var buttonBarView = Ti.UI.createView(candp.combine($$.footerView, {
        }));

        var buttonWidth = $$.platformWidth / buttons.length;
		var button = [];
        for (var index=0, len=buttons.length; index<len; index++) {
            button[index] = Ti.UI.createImageView(candp.combine($$.footerButton, {
                left: index * buttonWidth,
                width: buttonWidth,
                image: buttons[index].on || false ? buttons[index].imageOn : buttons[index].imageOff,
				on: buttons[index].on || false,
                index: index
            }));

			button[index].addEventListener('click', function(e) {
				// we need to keep track of the previously selected button
				// for aesthetic reasons (i.e. page transition animations!)
				var previousButtonIndex = null;

				// change the status of all the buttons to off, except the one we've just clicked
				for (var i=0, len=button.length; i<len; i++) {
					if (e.source.index != i) {
						previousButtonIndex = button[i].on ? i : previousButtonIndex; 
						button[i].on = false;
						button[i].image = buttons[i].imageOff;						
					}
				}

				// set our clicked button on
				e.source.on = true;
				e.source.image = buttons[e.source.index].imageOn;

				// trigger the button's onClick callback
				buttons[e.source.index].onClick(e.source.index, previousButtonIndex);
			});

            buttonBarView.add(button[index]);
        }

        return buttonBarView;
    };
})();