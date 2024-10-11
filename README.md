# AuerbachLook
Utilities that are common across apps in Joshua Auerbach Software.

## Philosophy
I am not maintaining this library in order to promote it as broadly useful to any community.  Rather, it is a collection of Swift sources that I have found useful in developing my own apps.  To avoid code duplication, I have factored these common elements out to the extent feasible.  

Since some (not all) of my apps are open source, I decided to make this library open source.  If it is useful, great.  If you want to contact me to discuss alternatives or how to make it better, great.  Otherwise, I am only changing it when it suits my other development goals.

The name `auerbachLook` sounds UI-oriented but some of the sources here are about other concerns.  I had to get the name somewhere.  The UI-oriented parts generally assume you are using UIKit without much reliance on the interface builder, which was my style in the past.  I have recently adopted SwiftUI and so perhaps these sources will start to become less useful even to me.

## My apps and libraries that Use It

- **Razor Puzzle** (in the app store but not open source)
- **anyCards** (open source but not in the app store)
- **Unigame-Core** (not an app, but another library, under development).  Open source
- **Image Match** (this was in the app store but has been withdrawn because Apple requested updates and I didn't want to spend time on them).  It is not open source and does not directly use `AuerbachLook` but contains older versions of some of the sources.
