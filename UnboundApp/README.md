# Dev setup

1. Install Cocoapods; on Mojave, `sudo gem install cocoapods` was giving me a Ruby interpreter error any time I tried to actually use `pod`, so I had to:
    1. `sudo gem install -n /usr/local/bin ruby`
    2. `sudo gem install -n /usr/local/bin cocoapods`
2. `cd path/to/unbound-mac/UnboundApp`
3. `pod install`
4. `open UnboundApp.xcworkspace/`
5. Manage Schemes and create a new scheme for Unbound and Unbound Trial (this may already be done?)
6. Build & run Unbound

# Releasing

1. Bump the `Build version` and `Short Build Version String` in the `/UnboundApp/Supporting Files/UnboundApp-Info.plist` file.
1. Using Xcode, build and archive the `Unbound Trial` target.
1. Open the Organizer window, and select the created archive.
1. Click `Export...`, and choose the `Developer ID` distribution method.
1. Choose the `Ryan Harter` development team.
1. Zip the resulting `.app` file using ditto.
    ```
    ditto -ck --rsrc --sequesterRsrc --keepParent input.app output.zip
    ```
1. Right click the archived file in organizer and show in finder.
1. Right click the xcarchive file and Show Package Contents.
1. Zip the dSYM file.
1. Upload the generated resources to [Paddle](https://vendors.paddle.com/release/519430#!) and [DevMate](https://dashboard.devmate.com/#3880/2/distribution/add)
