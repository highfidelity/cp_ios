/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
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
                    // one on one chat for MVP, 
                    // but it ought to be public chat in a fully released app
                    _fireEvent('chat', clickedButtonIndex, previousButtonIndex);
                }
            },
            {
                title: L('buttonbar_people'),
/*
                imageOff: 'images/buttonbar_people_off.png',
                imageOn: 'images/buttonbar_people_on.png',
*/
                imageOff: 'images/low_res_people_off.png',
                imageOn: 'images/low_res_people_on.png',
                onClick: function(clickedButtonIndex, previousButtonIndex) {
                    // show a list of nearby users
                    _fireEvent('userList', clickedButtonIndex, previousButtonIndex);
                    Ti.App.fireEvent('app:userList.getUsers');
                }
            },
            {
                title: L('buttonbar_missions'),
                imageOff: 'images/buttonbar_missions_off.png',
                imageOn: 'images/buttonbar_missions_on.png',
                on: true,
                onClick: function(clickedButtonIndex, previousButtonIndex) {
                    // show the missions in the nearby vicinity
                    _fireEvent('missionList', clickedButtonIndex, previousButtonIndex);
                }
            },
            {
                title: L('buttonbar_notifications'),
                imageOff: 'images/buttonbar_notifications_off.png',
                imageOn: 'images/buttonbar_notifications_on.png',
                onClick: function(clickedButtonIndex, previousButtonIndex) {
                    // stub for notifications as this isn't MVP
                    _fireEvent('notifications', clickedButtonIndex, previousButtonIndex);
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
                var clickedButtonIndex = (e.source.index === undefined) ? e.clickedButtonIndex : e.source.index;

                // change the status of all the buttons to off, except the one we've just clicked
                for (var i=0, len=button.length; i<len; i++) {
                    if (clickedButtonIndex != i) {
                        previousButtonIndex = button[i].on ? i : previousButtonIndex; 
                        button[i].on = false;
                        button[i].image = buttons[i].imageOff;                      
                    }
                }

                // set our clicked button on
                button[clickedButtonIndex].on = true;
                button[clickedButtonIndex].image = buttons[clickedButtonIndex].imageOn;

                // trigger the button's onClick callback
                buttons[clickedButtonIndex].onClick(clickedButtonIndex, previousButtonIndex);
            });

            buttonBarView.add(button[index]);
        }

        Ti.App.addEventListener('app:buttonBar.clicked', function(e) {
            switch(e.button_name) {
                case 'chat':
                    button[0].fireEvent('click', e);
                    break;
                case 'userProfile':
                    button[1].fireEvent('click', e);
                    break;
                case 'missionList':
                    button[2].fireEvent('click', e);
                    break;
            }
        });

        return buttonBarView;
    };
})();
