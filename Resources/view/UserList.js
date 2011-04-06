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


        userListView.add(tableView);

        Ti.App.addEventListener('app:userList.getUsers', function(e) {
            Ti.API.info('getting user list');
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
                        height: 15,
                        right:50,
                        text: users[user].nickname
                    });
                    row.add(userName);

                    var skills = Ti.UI.createLabel({
                        color: '#333333',
                        font:{fontSize:12, fontWeight:'bold', fontFamily:'Arial-ItalicMT'},
                        left:65,
                        top:20,
                        height:15,
                        width: 'auto',
                        text: users[user].skills
                    });
                    row.add(skills);
                    
                    var reviews = Ti.UI.createLabel({
                        color: '#3D00FF',
                        font:{fontSize:12,fontWeight:'bold', fontFamily:'Arial'},
                        left: 65,
                        top: 35,
                        height: 15,
                        text: users[user].ratings + ' ' + L('Reviews')
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
