Coffee & Power is an app that creates a community of mobile technology workers who can find each other, find places to work together, reward each other for help, and build a resume.

Building
--------

Because we use CocoaPods to manage dependencies for our app there are a couple of steps you'll need to take to get it to build successfully.

Since this is an Xcode project, let's assume you're on OS X and ruby is already installed.

Make sure you have Xcode's command line tools installed. This can be done by going to Xcode->Preferences->Downloads. You should see the option to install Command Line Tools under the Components tab.

1. Update rubygems to the latest version

    `sudo gem update --system`

2. Install the cocoapods gem
    
    `sudo gem install cocoapods`

3. Get cocoapods to pull down dependencies
    
    `pod install`

4. Open `candpiosapp.xcworkspace` - NOT `candpiosapp.xcodeproj`!

5. Make sure that the target in the top left is candpiosapp, not Pods.

![Xcode target](http://f.cl.ly/items/1z3m2w3N1T2b1E0R0I1b/Screen%20Shot%202012-11-09%20at%204.46.36%20PM.png)

And that's it! You should be all setup to build the app. 