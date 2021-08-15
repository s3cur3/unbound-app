# Unbound for Mac

A simple, no-nonsense photo manager and viewer for Mac. See the [marketing website](https://unboundapp.com/) for more information about what makes Unbound different from, say, Apple's Photos app.

## Unbound is now free*

Hi, I'm [Tyler](https://tylerayoung.com). I took over development of Unbound in early 2020 as a way to learn more about the Apple UI frameworks and to try my hand at building an app business. I was kind of sick of my day job, and working on Unbound provided a nice outlet.

Fast forward to today, I have a new full-time job that I'm quite happy in, and I've just not had the motivation or spare brain cycles to give Unbound the attention it needs. I dread support emails, and I feel vaguely guilty that I'm not working on improving the app more.

Thus, after many years of being a paid app, I've decided to make Unbound free (both in the sense of freedom and advice).

**There is absolutely no support available for Unbound.** (That's the whole point of me ceasing to sell it! 😅)

With that said, I believe it's more or less functional on Catalina and Big Sur.

## A note about copyrights

I'm releasing the code in this repo under [the 2-clause BSD license](https://opensource.org/licenses/BSD-2-Clause). This applies to the code only—neither the art assets nor the Unbound name or brand may be used in any commercial projects.

(If, tempted by the prospect of making tens of dollars per month, you fork Unbound and stick it up as-is on the App Store, you'll have it taken down for copyright infringement.)

## A note about code quality

In my estimation, this is not a codebase to model your own app off of.

- It's mostly Objective-C, and not particularly good Objective-C; sometimes downright horrifying Objective-C.
- The multithreading model is frankly a mess, and a huge source of bugs. If I had the time and inclination (and if Unbound made more than tens of dollars a month at its peak 😅) I would rewrite it either using the [Nuke Image Loading System](https://github.com/kean/Nuke) directly or adopting a very similar model to Nuke. (This could make a _very_ interesting project for someone else, though!)

So why open source it at all?

1. I'm reasonably proud of _my_ contributions to it. I've done quite a few bug fixes and rewrites that I'd like to put out in the open just as a portfolio piece. (I've squashed the commits prior to me taking it )
2. Some people like the app well enough, and if they want to hack on it, more power to them.
3. I have a vague dislike of codebases just disappearing into the void when they stop being financially viable.

## Dev setup

1. Install Cocoapods; on Mojave, `sudo gem install cocoapods` was giving me a Ruby interpreter error any time I tried to actually use `pod`, so I had to:
    1. `sudo gem install -n /usr/local/bin ruby`
    2. `sudo gem install -n /usr/local/bin cocoapods`
2. `cd path/to/unbound-mac/UnboundApp`
3. `pod install`
4. `open UnboundApp.xcworkspace/`
5. Build & run Unbound

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
1. **Update release notes!!**

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
1. **Update release notes!!**
