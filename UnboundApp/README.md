# Dev setup

1. Install Cocoapods; on Mojave, `sudo gem install cocoapods` was giving me a Ruby interpreter error any time I tried to actually use `pod`, so I had to:
    1. `sudo gem install -n /usr/local/bin ruby`
    2. `sudo gem install -n /usr/local/bin cocoapods`
2. `cd path/to/unbound-mac/UnboundApp`
3. `pod install`
4. `open UnboundApp.xcworkspace/`
5. Manage Schemes and create a new scheme for Unbound and Unbound Trial (this may already be done?)
6. Build & run Unbound

# Releasing via The Mac App Store
1. Bump the Version and Build fields in Project -> Unbound -> General (these correspond to `Build version` and `Short Build Version String` in the `/UnboundApp/Supporting Files/UnboundApp-Info.plist` file)
1. Using Xcode, build and archive the `Unbound Trial` target.
1. Open the Organizer window, and select the created archive.
1. Click Distribute App
1. Mac App Store, Next
1. Upload, Next
1. Remain opted in to uploading symbols, Next
1. Automatically manage signing, Next
1. If it gives you an error about a missing signing cert, add it (currently in Dropbox/Conversion Insights/Apple Signing Certificate.p12, password is in 1Password under "Conversion Insights signing certificate")

# Releasing via Paddle

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
    ditto -ck --rsrc --sequesterRsrc --keepParent input.app output.zip
    ```
1. Upload to the web
