/*
 * @copyright Copyright (c) Coffee And Power Inc. 2011 All Rights Reserved. 
 * http://www.coffeeandpower.com
 * @author H <h@singinghorsestudio.com>
 * 
 * @brief  We use app.js mainly as a bootstrap file to include our app namespace 'candp'
 * 
 */

Ti.include('candp.js');

candp.app.mainWindow = candp.view.createApplicationWindow();
candp.app.mainWindow.open();
