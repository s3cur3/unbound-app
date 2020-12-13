## Dev setup

1. Install Cocoapods; on Mojave, `sudo gem install cocoapods` was giving me a Ruby interpreter error any time I tried to actually use `pod`, so I had to:
    1. `sudo gem install -n /usr/local/bin ruby`
    2. `sudo gem install -n /usr/local/bin cocoapods`
2. `cd path/to/unbound-mac/UnboundApp`
3. `pod install`
4. `open UnboundApp.xcworkspace/`
5. Manage Schemes and create a new scheme for Unbound and Unbound Trial (this may already be done?)
6. Build & run Unbound

### Using Swift Format

We format our Swift code using SwiftFormat, the proposed-for-standardization formatter from Dave Abrahams et al.

CocoaPods installs it for the sake of providing warnings, but you'll probably want it installed as a command line tool as well for the sake of auto-fixing stuff.

Install it like this: `$ brew install swiftformat`

Use it like this:

    cd UnboundApp
    swiftformat .

Additionally, you may want to install the Xcode editor extension: `$ brew install swiftformat-for-xcode`

This will install SwiftFormat for Xcode in your Applications folder. Double-click the app to launch it, and then follow the on-screen instructions. Once you have launched the app and restarted Xcode, you'll find a SwiftFormat option under Xcode's Editor menu.
 

## Releasing via The Mac App Store
1. Bump the Version and Build fields in Project -> Unbound -> General (these correspond to `Build version` and `Short Build Version String` in the `/UnboundApp/Supporting Files/UnboundApp-Info.plist` file)
1. Using Xcode, build and archive the `Unbound` target.
1. Open the Organizer window, and select the created archive.
1. Click Distribute App
1. Mac App Store, Next
1. Upload, Next
1. Remain opted in to uploading symbols, Next
1. Automatically manage signing, Next
1. If it gives you an error about a missing signing cert, add it (currently in Dropbox/Conversion Insights/Apple Signing Certificate.p12, password is in 1Password under "Conversion Insights signing certificate")
1. # **Update release notes!!**

## Releasing the Demo via the Web Site

1. Using Xcode, build and archive the `Unbound Trial` target.
1. Open the Organizer window and select the Mac App Store build you did above
1. Click `Distribute App`, and choose the `Developer ID` distribution method.
1. Have it automatically manage signing
1. Choose to upload to Apple (this is necessary for notarization)
1. Leave the window open for as long as it takes (usually a couple minutes)
1. Once notarized, you'll be able to select the Trial build in the Organizer, and the lower right corner will have a button to Export Notarized App. Do that.
1. Verify the exported app looks good: `$ spctl -a -v "Unbound Trial.app"`
    - Ensure it says both "accepted" and "source=Notarized Developer ID"—not *just* "source=Developer ID"
1. Zip the resulting `.app` file using ditto.
    ```
    ditto -ck --rsrc --sequesterRsrc --keepParent "Unbound Trial.app" "Unbound Trial.app.zip"
    ```
1. Move to the `unboundapp.com` repo: `$ mv "Unbound Trial.app.zip" ~/Documents/repos/unboundapp.com/downloads/`
1. Add: `$ cd ~/Documents/repos/unboundapp.com/downloads/ && git add "Unbound Trial.app.zip"`
1. Commit: `$ git commit -m "feat (release): Trial version 1.3.5"`
1. Push: `$ git push`
1. # **Update release notes!!**
