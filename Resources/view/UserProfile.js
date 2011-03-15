/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
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
            backgroundImage: 'images/default_background.png',
            visible: false
        }));

        // use a dialog container
        var containerView = Ti.UI.createView({
            top: 20,
            bottom: 20,
            left:20,
            right: 20,
            backgroundColor: '#FFFFFF',
            borderRadius: 15
        });
        userProfileView.add(containerView);
       
        var userNameLabel = Ti.UI.createLabel(candp.combine($$.largeText, {
            left: 20,
            top: 20
        }));
        containerView.add(userNameLabel);

        containerView.add(Ti.UI.createView(candp.combine($$.spacerLine, {
            top: 50
        })));

        var userImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            top: 55,
            left: 20
        }));
        containerView.add(userImage);

        // *TODO: Add profile user rating star image
        // *TODO: Add profile user reviews star image
        // *TODO: Add profile user id verified image
        // *TODO: Add profile user skillz label


        var makeOfferButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('make_offer'),
            top: 230,
            height: 37,
            left: 5,
            width: 130
        }));
        containerView.add(makeOfferButton);


        var initiateChatButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('chat1_1'),
            top: 230,
            height: 37,
            right: 5,
            width: 130
        }));
        containerView.add(initiateChatButton);


        // *TODO: Add profile user other profile info label
        // *TODO: Add event listener for make offer button
        // *TODO: Add event listener for initiate 1:1 chat button



        userProfileView.addEventListener('click', function(e) {
            userProfileModel.getUserProfile(e, function(profile) {
                candp.view.alert('Profile', 'Status text = ' + profile.status_text);
                Ti.API.info('nickname = ' + profile.nickname);
                userNameLabel.text = profile.nickname;
                
                userProfileModel.getUserImage({
                    image_id: profile.photo
                }, function(image) {
                    Ti.API.info('image = ' + image);
                    userImage.image = candp.config.baseUrl + image;
                });

            });
        });

        return userProfileView;
    };
})();
