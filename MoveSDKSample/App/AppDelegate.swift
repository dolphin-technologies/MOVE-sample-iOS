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

import BackgroundTasks
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
	let backgroundRefreshIdentifier = "in.dolph.sdk.test.task.refresh"
	let backgroundRefreshInterval: TimeInterval = 60 * 60 * 4 /// 4h

	func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {

		/*
		The initializationAPI must be executed before didFinishLaunchingWithOptionsreturns. We recommend calling it in willFinishLaunchingWithOptions .
		
		Exceptions might apply, where the SDK is not initialized on app launch.  First initialization is a good example, where the app would only initialize the SDK after onboarding the user and requesting permissions.
		*/
		
		SDKManager.shared.initSDK(withOptions: launchOptions)
		
		return true
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
		registerBackgroundTask(application: application)
		return true
	}

	func registerBackgroundTask(application: UIApplication) {
		BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundRefreshIdentifier, using: nil) { task in
			SDKManager.shared.performFetch { result in
				task.setTaskCompleted(success: result != .failed)
			}
			self.scheduleBackgroundFetch(application: application)
		}

		scheduleBackgroundFetch(application: application)

#if targetEnvironment(simulator)
		/// Fallback to old background fetch implementation
		application.setMinimumBackgroundFetchInterval(backgroundRefreshInterval)
#endif
	}

	func scheduleBackgroundFetch(application: UIApplication) {
		let request = BGAppRefreshTaskRequest(identifier: backgroundRefreshIdentifier)
		request.earliestBeginDate = Date(timeIntervalSinceNow: backgroundRefreshInterval)
		do {
			try BGTaskScheduler.shared.submit(request)
			print("background refresh scheduled")
			return
		} catch {
			print("Couldn't schedule app refresh \(error.localizedDescription)")
		}
	}

	/// Fallback to old background fetch implementation
	func application(_: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		SDKManager.shared.performFetch(completionHandler: completionHandler)
	}
}

