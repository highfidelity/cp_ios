/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief View for the mission details.  This view gives more detailed information
 * regarding a particular mission.  From here, the user is able to chat with the 
 * mission creator, view the profile of the mission creator, or make an offer to
 * carry out the mission
 * 
 */

(function() {
    candp.view.createMissionDetailsView = function (args) {
        var user_id;
        var missionDetailsView = Ti.UI.createView(candp.combine($$.contained, {
            backgroundColor: '#FFFFFF',
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
        missionDetailsView.add(containerView);

        var authorImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            defaultImage: 'images/no_picture.jpg',
            top: 20,
            left: 20
        }));
        authorImage.addEventListener('click', function(e) {
            Ti.App.fireEvent('app:buttonBar.clicked', {button_name: 'userProfile'});
            setTimeout(function() {
                missionDetailsView.hide();
                Ti.App.fireEvent('app:userProfile.getUserProfile', {
                    user_id: user_id
                });
            }, 100);
        });

        containerView.add(authorImage);

        var missionTitle = Ti.UI.createLabel(candp.combine($$.titleText, {
            top: 20,
            left: 130,
            right: 20
        }));
        containerView.add(missionTitle);

        var missionDetails = Ti.UI.createLabel(candp.combine($$.mediumText, {
            top: 125,
            left: 20,
            right: 20
        }));
        containerView.add(missionDetails);


        var mapImage = Ti.UI.createImageView(candp.combine($$.imageView, {
            top: 190,
            left: 20,
            right: 20,
            height: 'auto',
            width: 'auto',
            canScale: false
        }));
        containerView.add(mapImage);


        var backButton = Ti.UI.createButton({
            bottom: 10,
            title: 'back',
            left: 10,
            height: 30,
            width: 100
        });
        backButton.addEventListener('click', function(e) {
            missionDetailsView.hide();
        });
        containerView.add(backButton);



        Ti.App.addEventListener('app:missionDetail.show', function(mission) {
            userProfileModel.getUserImage({
                image_id: mission.photo
            }, function(image) {
                authorImage.image = image;
            });

            user_id = mission.author_id;
            mapImage.image = 'http://maps.google.com/maps/api/staticmap?markers=color:red%7Clabel:M|' + mission.lat + ',' + mission['long'] + '&zoom=16&size=300x160&sensor=false';

            missionTitle.text = mission.title;
            missionDetails.text = mission.description;
            missionDetailsView.show();
        });

        // *TODO: Add mission detail label
        // *TODO: Add mission detail due date label
        // *TODO: Add mission detail due date as words label
        // *TODO: Add mission detail posted by image
        // *TODO: Add mission detail posted by label
        // *TODO: Add mission detail user profile button (arrow)
        // *TODO: Add mission detail make offer button
        // *TODO: Add mission detail initiate 1:1 chat button
        // *TODO: Add event listener for make offer button
        // *TODO: Add event listener for initiate 1:1 chat button

        return missionDetailsView;
    };
})();
