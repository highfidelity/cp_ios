/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for top header bar.  We use our own custom view so that we have 
 * the same layout in both Android and iPhone
 * 
 */

(function() {
    candp.view.createHeaderBarView = function (options) {
        var headerBarView = Ti.UI.createView(candp.combine($$.headerView, options));

        var headerBarTitle = Ti.UI.createLabel(candp.combine($$.headerText, {
			text: L('coffee_and_power')
		})); 
		headerBarView.add(headerBarTitle);

		var loginButton = Ti.UI.createButton(candp.combine($$.variableTopRightButton, {
            title: L('login') 
        }));

		loginButton.addEventListener('click', function(e) {
            // *FIXME: move the button specific logic into the model
            if (e.source.title === L('login')) {
				candp.model.xhr(
	                // *FIXME: use details from the dialog box, not hardcoded details ...
	                candp.config.loginUrl,
	                'POST',
	                {
	                    action: 'login',
	                    username: 'h@singinghorsestudio.com',
	                    password: 'xxxxxxxx'
	                }, 
	                function(e) {
                        Ti.App.fireEvent('app:headerBar.changeState', {
                            newState: 'loggedIn'
                        });
	                }
	            );
            }

            if (e.source.title === L('logout')) {
				candp.model.xhr(
	                candp.config.logoutUrl,
	                'POST',
	                {}, 
	                function(e) {
                        // clear any cookie we have stored
                        candp.sessionId = '';
                        Ti.App.Properties.removeProperty('sessionId');

                        // *TODO: i18n the strings in this message ...
	                    candp.view.alert('Logged Out', 'You have been logged out');

                        Ti.App.fireEvent('app:headerBar.changeState', {
                            newState: 'loggedOut'
                        });
	                }
	            );
            }

		});

		headerBarView.add(loginButton);



        // *FIXME: move this logic into the model
        Ti.App.addEventListener('app:headerBar.changeState', function(e) {
            if (e.newState === 'loggedIn') {
			    loginButton.title = L('logout');

                // get the username, balance, etc
                candp.model.xhr(
                    candp.config.actionServerUrl,
                    'POST',
                    {
                        action: 'isLoggedIn'
                    },
                    function(e) {
                        var response = JSON.parse(e.response);
                        headerBarTitle.text = response.params.userData.nickname;
                    }
                );
            }

            if (e.newState === 'loggedOut') {
			    loginButton.title = L('login');
                headerBarTitle.text = L('coffee_and_power');
            }
        });
		

		// *TODO: Add refresh button on left hand side of the header bar

        // *FIXME: Remove this label when we go live!
        // Keep a check on our memory usage while we work
        var memoryCheck = Ti.UI.createLabel(candp.combine($$.headerText, {
            left: 5,
            height: 20,
            width: 100,
			font: {
				fontSize:10,
				fontWeight:'bold'
			},
            text: String.format('%5.2f', Ti.Platform.availableMemory)
		}));
		headerBarView.add(memoryCheck);

        // *FIXME: Remove this callback when we go live!
        setInterval(function() {
            memoryCheck.text = String.format('%5.2f', Ti.Platform.availableMemory);            
        }, 1000);

        return headerBarView;
    };
})();