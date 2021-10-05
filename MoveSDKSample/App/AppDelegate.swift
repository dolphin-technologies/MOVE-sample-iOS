/*
 *  Copyright 2021 Dolphin Technologies GmbH
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *       http:*www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 * /
 */

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

		UINavigationBar.appearance().backgroundColor = UIColor(hue: CGFloat(drand48()), saturation: 1, brightness: 1, alpha: 1)
			//UIColor(red: 7, green: 18, blue: 48, alpha: 1.0)

		/*
		The initializationAPI must be executed before didFinishLaunchingWithOptionsreturns. We recommend calling it in willFinishLaunchingWithOptions .
		
		Exceptions might apply, where the SDK is not initialized on app launch.  First initialization is a good example, where the app would only initialize the SDK after onboarding the user and requesting permissions.
		*/
		
		SDKManager.shared.initSDKIfPossible(withOptions: launchOptions)
		
		
		return true
	}
}
