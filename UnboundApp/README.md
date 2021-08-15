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
