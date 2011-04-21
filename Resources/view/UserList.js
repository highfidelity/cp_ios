/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author Hans
 * 
 * @brief View for the users table.  Once connected to the CandP server, the 
 * user sees a table of users that are within the user's vicinity.  Clicking 
 * on a users row opens the users detail view. (not yet)
 * 
 */

(function() {
    candp.view.createUserListView = function (args) {
        var data = [];
        var users_data = [];

        var userListView = Ti.UI.createView(candp.combine($$.stretch, {
            visible: false
        }));


        var tableView = Ti.UI.createTableView(candp.combine($$.tableView, {
            top: 50,
            left: 0,
            right: 0,
            bottom: 30,
            data: data
        }));

        tableView.addEventListener('click', function(e) {
            // There's a naming clash on mission.type because Titanium framework adds a 'type' 
            // property to describe the type of object that sent the event
            //missions_data[e.index].mission_type = missions_data[e.index].type;
            Ti.App.fireEvent('app:userProfile.show', users_data[e.index]);
            Ti.App.fireEvent('headerBar:backButton.show', {
                destinationView: 'userList',
                destinationIndex: 1
            });
        });

        userListView.add(tableView);

        Ti.App.addEventListener('app:userList.getUsers', function(e) {
            usersModel.getUsersList(e, function(users) {
                data = [];
                users_data = users;

                // fill in the table with users
                for (var user in users) {
                    var row = Ti.UI.createTableViewRow(candp.combine($$.tableViewRow, {
                        height: 65,
                        hasChild: true
                    }));

                    var profileImage = Ti.UI.createImageView(candp.combine($$.imageView,{
                        defaultImage: 'images/no_picture.jpg',
                        image: (users[user].filename != null) ? candp.config.baseUrl + users[user].filename : 'images/no_picture.jpg',
                        width: 55,
                        height: 55,
                        top: 5,
                        left: 5,
                        canScale: true
                    }));
                    row.add(profileImage);
                    
                    var userName = Ti.UI.createLabel({
                        color:'#000000',
                        font:{fontSize:16,fontWeight:'bold', fontFamily:'Arial'},
                        left:65,
                        top:5,
                        height: 22,
                        right:50,
                        text: users[user].nickname
                    });
                    row.add(userName);

                    var skills = Ti.UI.createLabel({
                        color: '#333333',
                        font:{fontSize:12, fontWeight:'bold', fontFamily:'Arial-ItalicMT'},
                        left:65,
                        top:28,
                        height:17,
                        width: 'auto',
                        text: users[user].skills
                    });
                    row.add(skills);
                    
                    var reviews = Ti.UI.createLabel({
                        color: '#3D00FF',
                        font:{fontSize:12,fontWeight:'bold', fontFamily:'Arial'},
                        left: 65,
                        top: 45,
                        height: 15,
                        text: String.format(L('reviews'), users[user].ratings.toString())
                    });
                    row.add(reviews);

                    var distance = Ti.UI.createLabel({
                        color: '#000000',
                        font:{fontSize:12, fontWeight:'bold', fontFamily:'Arial'},
                        right:0,
                        top:45,
                        height:15,
                        width: 'auto',
                        text: parseFloat(users[user].distance).toFixed(1) + ' ' + L('miles')
                    });
                    row.add(distance);

                    data.push(row);
                }
                tableView.setData(data);
            });
        });

        return userListView;
    };
})();
