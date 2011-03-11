/*
 * @copyright (c) Copyright Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for a user profile.  From here we can make an offer to the user
 * whose profile we're viewing, or initiate a 1:1 chat
 * 
 */

(function() {
    candp.view.createUserProfileView = function (args) {
        var userProfileView = Ti.UI.createView(candp.combine($$.stretch, {
            visible: false
        }));

        userProfileView.add(Ti.UI.createLabel(candp.combine($$.headerText, {
            text: L('title_userprofile')
        })));

		// *TODO: Add profile user name label
		// *TODO: Add profile user photo image
		// *TODO: Add profile user rating star image
		// *TODO: Add profile user reviews star image
		// *TODO: Add profile user id verified image
		// *TODO: Add profile user skillz label
		// *TODO: Add profile user make offer button
		// *TODO: Add profile user initiate 1:1 chat button
		// *TODO: Add profile user other profile info label
		// *TODO: Add event listener for make offer button
		// *TODO: Add event listener for initiate 1:1 chat button

        return userProfileView;
    };
})();