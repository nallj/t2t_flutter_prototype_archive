# t2t_flutter_prototype

A new Flutter project.

## References

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)
- [state management techniques](https://www.spec-india.com/blog/flutter-state-management)

## Getting Started
0. Download Visual Studio Code (VSC), the officially supported IDE of the team.
   In addition, you should acquire the following extensions:
  * `Dart` by `Dart Code`
  * `Flutter` by `Dart Code`
  * `GitLense - Git supercharged` by `GitKraken`
  * `Git Blame` by `Wade Anderson`
1. Fork the [upstream repo](https://github.com/nallj/t2t_flutter_prototype).
2. Clone the forked repo.
3. Navigate your terminal to the repo base and run `flutter pub get` to get project dependencies.
3. Add necessary secrets to their appropriate locations.
  * Add `MAPS_API_KEY=<redacted>` to `android/local.properties`. TODO: Remove this later.
4. Open `android` subdirectory in Android Studio.
   Doing so will run some Gradle actions to ready the emulator.
   Once the project fully loads you can close Android Studio.
5. Enable USB debugging on your mobile device.
6. Open the base of the repo in VSC, plug your mobile device into your computer, and run the debugger.
7. Create a `credentials` subdirectory under `assets`.
   You will need to acquire and save `bucket_credentials.json` from GCP.

# Troubleshooting
* Encountering `Could not determine the dependencies of task ':app:processDebugManifest'.` on attempt to debug?
  * Did you follow the Getting Started steps in this document to setup your repo?
    If not, you're likely missing a necessary entry, e.g. `MAPS_API_KEY`
  * If that doesn't work, open the `android` directory in Android Studio; this should reveal in the build pane why the project can't be built.

## TODO

- Many, many things
- Implement action tracking for debugging
  - User actions
  - Application state changes
- Handle the situation where the user doesn't allow access to their current position.
- At tow destination screen, give user option to select a nearby mechanic shop.
- While customer is waiting for provider to engage...
  - Is there a timeout for this?
  - Provider auction functionality
- Error handling
  - registration attempt
  - login attempt
- Provider UX
  - Either add more details to the items in the provider's select screen, or have an intermediate 'more details' page before moving onto provider_engaged.
    Moving onto provider_engaged should automatically commit the driver to that request.
    Add a confirm modal before it commits them.
- Remove all reference to secrets!!!

## Stuff I had to Do That I will likely forget

- Set up a project in [GCP](https://console.cloud.google.com) for cloud services. Services you will need:
  - Google Maps Platform
    - "Maps SDK for Android" (not Geolocation API)
    - "Maps SDK for iOS"
    - "Directions API"
  -
- `AndroidManifest.xml` changes
  - Set up `<meta-data android:name="com.google.android.geo.API_KEY" android:value="your API key"/>` within AndroidManifest.xml.
    You get the API key from GCP.
    - Don't forget to [not check in the secret](https://developers.google.com/maps/documentation/android-sdk/start?hl=en#add_the_api_key_to_your_app)
  - "ACCESS_FINE_LOCATION or ACCESS_COARSE_LOCATION"
- `AppDelegate.swift`
  - Add `GMSServices.provideAPIKey("your API key")`
- `Info.plist`
  - Add
    ```
    <key>NSLocationWhenInUseUsageDescription</key>
	  <string>This app needs access to location when open.</string>
    ```
- `pubsec.yaml`
  - Add
    ```
    flutter_polyline_points: ^1.0.0
    geolocator: ^7.4.0
    geocoding: ^2.0.1
    google_maps_flutter: ^2.0.6
    ```

## Stuff to keep in mind

- "When you really do want to start a fire-and-forget Future, the recommended way is to use unawaited from package:pedantic."
  <https://dart-lang.github.io/linter/lints/unawaited_futures.html>