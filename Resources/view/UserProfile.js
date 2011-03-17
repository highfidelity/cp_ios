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
        var userProfileView = Ti.UI.createView(candp.combine($$.contained, {
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
       
        // the user's nickname
        var userNameLabel = Ti.UI.createLabel(candp.combine($$.largeText, {
            left: 20,
            top: 20
        }));
        containerView.add(userNameLabel);

        containerView.add(Ti.UI.createView(candp.combine($$.spacerLine, {
            top: 50
        })));

        // the user's photo
        var userImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            defaultImage: 'images/no_picture.jpg',
            top: 55,
            left: 20
        }));
        containerView.add(userImage);

        // has anyone favorited this user?
        var favoritedStarImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            defaultImage: 'images/transparent.png',
            image: 'images/gold_star.png',
            visible: false,
            left: 130,
            top: 57,
            width: 19,
            height: 18
        }));
        containerView.add(favoritedStarImage);

        var favoritedLabel = Ti.UI.createLabel(candp.combine($$.mediumText, {
            visible: false,
            left: 160,
            top: 57
        }));
        containerView.add(favoritedLabel);

        // has anyone reviewed this user?
        var reviewsStarImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            defaultImage: 'images/transparent.png',
            image: 'images/gold_star.png',
            visible: false,
            left: 130,
            top: 100,
            width: 19,
            height: 18
        }));
        containerView.add(reviewsStarImage);

        var reviewsLabel = Ti.UI.createLabel(candp.combine($$.mediumText, {
            visible: false,
            left: 160,
            top: 100
        }));
        containerView.add(reviewsLabel);

        //is this user verified?
        var verifiedIdImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            defaultImage: 'images/transparent.png',
            image: 'images/verified_id.png',
            visible: false,
            left: 125,
            top: 135,
            width: 29,
            height: 20
        }));
        containerView.add(verifiedIdImage);

        var verifiedIdLabel = Ti.UI.createLabel(candp.combine($$.mediumText, {
            text: L('id_verified'),
            visible: false,
            left: 160,
            top: 137
        }));
        containerView.add(verifiedIdLabel);

        // what skillz does the user have?
        var skillsLabel = Ti.UI.createLabel(candp.combine($$.mediumText, {
            top: 158,
            left: 20,
            right: 20,
            height: 140
        }));
        containerView.add(skillsLabel);

        // make an offer to the user
        var makeOfferButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('make_offer'),
            bottom: 20,
            height: 37,
            left: 5,
            width: 130
        }));
        containerView.add(makeOfferButton);

        // get chatting 1:1 with the user
        var initiateChatButton = Ti.UI.createButton(candp.combine($$.button, {
            title: L('chat1_1'),
            bottom: 20,
            height: 37,
            right: 5,
            width: 130
        }));
        containerView.add(initiateChatButton);


        // *TODO: Add profile user other profile info label
        // *TODO: Add event listener for make offer button
        // *TODO: Add event listener for initiate 1:1 chat button


        Ti.App.addEventListener('app:userProfile.show', function(e) {
            Ti.App.fireEvent('app:buttonBar.click', {
                nextViewToShow: 'userProfile'
            });
            userProfileView.show();
        });

        Ti.App.addEventListener('app:userProfile.getUserProfile', function(e) {
            userProfileModel.getUserProfile(e, function(profile) {
                userProfileModel.getUserImage({
                    image_id: profile.photo
                }, function(image) {
                    Ti.API.info('image = ' + image);
                    userImage.image = image;
                });

                userNameLabel.text = profile.nickname;
                skillsLabel.text = profile.skill_list;

                if (profile.verified_id == 1) {
                    verifiedIdImage.visible = true;
                    verifiedIdLabel.visible = true;
                } else {
                    verifiedIdLabel.visible = false;
                    verifiedIdImage.visible = false;
                }

                if (parseInt(profile.reviews_count) > 0) {
                    reviewsStarImage.visible = true;
                    reviewsLabel.text = String.format(L('reviews'), profile.reviews_count.toString());
                    reviewsLabel.visible = true;
                } else {
                    reviewsStarImage.visible = false;
                    reviewsLabel.visible = false;
                }

                if (parseInt(profile.favorite_count) > 0) {
                    favoritedStarImage.visible = true;
                    favoritedLabel.text = String.format(L('users_have_favorited'), profile.favorite_count.toString());
                    favoritedLabel.visible = true;
                } else {
                    favoritedStarImage.visible = false;
                    favoritedLabel.visible = false;
                }

            });
        });

        return userProfileView;
    };
})();
