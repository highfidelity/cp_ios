/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief Model for top header bar.  We put all our complex logic here to keep the view clean
 * 
 */


var headerBarModel = {};

(function() {
    headerBarModel.loginButton = function(e) {
        switch(e.source.title) {
            case L('login'):
                Ti.App.fireEvent('app:login.toggle');
                break;

            case L('logout'):
                candp.model.xhr(
                    candp.config.logoutUrl,
                    'POST',
                    {}, 
                    function(e) {
                        // we've logged out, so let the user know
                        candp.view.alert(L('logged_out'), L('logged_out_message'));
                        Ti.App.fireEvent('app:headerBar.changeState', {
                            newState: 'loggedOut'
                        });
                    }
                );
                break;
        }         
    };

    headerBarModel.changeState = function(e) {
        // helper function to be used in the setInterval
        function _getUserBalance() {
            headerBarModel.getUserBalance(function(balance) {
                Ti.App.fireEvent('headerBar:headerBarBalance.changeText', {
                    newText: '$' + balance
                });
            });            
        }

        switch(e.newState) {
            case 'loggedIn':
                // let's check that we're really logged in
                candp.model.xhr(
                    candp.config.actionServerUrl,
                    'POST',
                    {
                        action: 'isLoggedIn'
                    },
                    function(e) {
                        var params = JSON.parse(e.response).params;
                        var logged = params.logged;
                        
                        if (logged === 'true') {
                            // we're logged in, so 
		                    // ... collect the missions now that we've logged in
			                Ti.App.fireEvent('app:missionList.getMissions');
                    
                            // ... and register for APN (Apple Push Notifications)
                            if (candp.osname === 'iphone') {
                                Ti.App.fireEvent('app:applicationWindow.registerForPushNotifications');
                            }

                            // ... and we can get the nickname and balance etc
                            Ti.App.fireEvent('headerBar:loginButton.changeText', {
                                 newText: L('logout')
                            });

                            // we need the user's balance right now
                            _getUserBalance();

                            Ti.App.fireEvent('headerBar:headerBarNickname.changeText', {
                                 newText: params.userData.nickname + ' - '
                            });


                            // ... and reload the chat page
                            Ti.App.fireEvent('app:chat.initiateChat');

                            // let's go get our balance every x minutes
                            headerBarModel.getUserBalanceIntervalId = setInterval(_getUserBalance, candp.config.getBalanceTime);
                        }
                    }
                );
                break;

            case 'loggedOut':
	            Ti.App.fireEvent('headerBar:loginButton.changeText', {
	                 newText:  L('login')
	            });
	            Ti.App.fireEvent('headerBar:headerBarNickname.changeText', {
	                 newText: L('coffee_and_power')
	            });
	            Ti.App.fireEvent('headerBar:headerBarBalance.changeText', {
	                 newText: ' '
	            });

                // ... and reload the chat page, but not logged in so it has to be group chat
                Ti.App.fireEvent('app:chat.loadGroupChat');

                // stop collecting our balance
                clearInterval(headerBarModel.getUserBalanceIntervalId);
                break;
        }    
    };

    headerBarModel.getUserBalance = function(callback) {
        candp.model.xhr(
            candp.config.actionServerUrl,
            'POST',
            {
                action: 'getUserBalance'
            },
            function(e) {
                var response = JSON.parse(e.response);
                if (response.params.balance) {
                    callback(response.params.balance);                    
                }
            }
        );
    };


})();
