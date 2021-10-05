# Dolphin MOVE SDK Sample App
Reference: MOVE iOS SDK [documentation](https://docs.movesdk.com/).

A sample application that uses the Dolphin MOVE SDK. 
This project could be a great starter project for new apps, else AppManager.swift file is a recommended starting point for embedding the SDK in already existing projects.

## App cycle goes as follows:

On first app initialization, the app will launch but wont do anything.

#### Toggle Activation switch: ON
- Creates a user for you if no user already exists
- Init the SDK (first time only)
- If required permissions were:
	- granted: SDK will be in ready state and app will automatically start SDK services using ‘startAutomaticDetection’ API
	- denied: SDK will be in an error state waiting for the errors to be resolved

#### Toggle Activation switch: OFF
- Stops the SDK services using ‘stopAutomaticDetection’ API.
- As the sample app is using the ‘stopAutomaticDetection’ API and not ‘shutdown’, the SDK state will only transit to ready state and not shutdown. Hence, future on toggles will only start SDK services without re-creating a user or re-initializing the SDK.

The sample app persists the SDK activation toggling State is persisted for future initializations.


For simplicity, the sample app uses SwiftUI to define app views and Combine to subscribe and render MOVE SDK listeners changes. 
Incase your app doesn't use Combine, feel free to replace the `SDKStateMonitor.swift` with your own subscription pattern. 

## To run this project:

1. Request a product API Key by contacting Dolphin MOVE.
2. Using the terminal, navigate to the project folder and run `pod install`
3. From finder, open the repository's workspace MoveSDKSample.xcworkspace with Xcode.
4. In Configuration.plist file, replace the Bearer value with the product API Key you received.
5. Clean, build and run the application on your device

## Starting Point:

### SDK Setup:

#### Authorization

After contacting us and getting a  product API key, use it to fetch a MoveAuth from the Move Server. MoveAuth object will be passed to the SDK on initialization and be used by the SDK to authenticate its services.

If the provided MoveAuth was invalid, the SDK will not initialize and complete with MoveConfigurationError.authInvalid. Check Initialization for more details about possible outcomes.


#### Configuration

MoveConfig allows host apps to configure which of the licensed Move services should be enabled. It could be based on each user preference or set from a remote server. All permissions required for the requested configurations must be granted. SDKSate.Error will be triggered otherwise.

#### State Listener:

The host app is expected to set its `SDKStateListener` before initializing the SDK to intercept the MoveSDKState changes caused by calling the `initialize` API.

The provided block could then start the SDK when MoveSDKState is ready or handle errors if occurred. The provided block could look something like this: 

#### SDK Initialization:

The SDK  `initialization` API must be executed before the App delegate's method  `didFinishLaunchingWithOptions` returns. We recommend calling it in `willFinishLaunchingWithOptions`. Check in the app delegate  `SDKManager.shared.initSDKIfPossible(withOptions: launchOptions)` 

Exceptions might apply, where the SDK is not initialized on app launch.  First initialization is a good example, where the app would only initialize the SDK after onboarding the user and requesting permissions. 

## Support
Contact info@dolph.in
 
## License

The contents of this repository are licensed under the
[Apache License, version 2.0](http://www.apache.org/licenses/LICENSE-2.0).
