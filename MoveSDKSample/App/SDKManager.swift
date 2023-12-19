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

import Combine
import UIKit
import DolphinMoveSDK


/// Main Interface for managing the MOVE SDK and its services.
class SDKManager {

	/// SDKManager shared instance.
	static let shared = SDKManager()
	
	/// SDK state UI observer
	let statesMonitor = SDKStatesMonitor()

	/**
	SDK activation state
	
	An app level flag representing if the SDK Service should be activated or not.
	Usually this flag will be set:
	- After the user's login and permissions are granted.
	- Or reverted by  `shutdown()` or `stopAutomaticDetection()` when user wants to stop tracking or logs out.

	In this app, this state will be set from toggling in the UI the SDK activation toggle switch.
	*/
	var isSDKStarted: Bool = false {
		didSet {
			/* persist state*/
			UserDefaults.standard.set(isSDKStarted, forKey: "isSDKStarted")
		}
	}
	
	/// MOVE SDK instance
	let moveSDK: MoveSDK = MoveSDK.shared

	/// MOVE SDK authentication object
	var auth: MoveAuth? {
		didSet {
			
			/* presist auth*/
			if let encoded = try? JSONEncoder().encode(auth) {
				UserDefaults.standard.set(encoded, forKey: "auth")
			}
		}
	}

	init() {
		let decoder = JSONDecoder()
		/* Decode possibly persisted user auth */
		if let data: Data = UserDefaults.standard.object(forKey: "auth") as? Data {
			auth = try? decoder.decode(MoveAuth.self, from: data)
			if let contractID = auth?.userID {
				statesMonitor.set(contractID: contractID)
			}
		}
		
		/* Decode possibly persisted isSDKStarted bool */
		self.isSDKStarted = UserDefaults.standard.bool(forKey: "isSDKStarted")
	}

	/**
	Initiates the MOVE SDK if possible on wake up
	
	#Inits the SDK if:
	
	- A persisted MoveAuth exists
	- SDK activation state is set to activated.
	*/
	func initSDK(withOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) {
		/* 1. setup listeners for the SDK callbacks */
		moveSDK.setLogListener(sdkLogListener)
		moveSDK.setAuthStateUpdateListener(sdkAuthStateListener)
		moveSDK.setServiceWarningListener(sdkWarningListener)
		moveSDK.setServiceFailureListener(sdkFailureListener)
		moveSDK.setSDKStateListener(sdkStateListener)
		moveSDK.setTripStateListener(sdkTripStateListener)
		moveSDK.initialize(launchOptions: options)
	}

	/// Toggles MOVE SDK Activation State
	func toggleMoveSDKState() {

		/* Switch on latest state to determine the action */
		switch moveSDK.getSDKState() {
		case .uninitialized:
			registerUserIfNeeded { result in
				switch result {
				case let .success(auth):
					self.initializeSDK(auth: auth)
					self.moveSDK.startAutomaticDetection()
					self.isSDKStarted = true
				case let .failure(error):
					/* Inform the monitor with the errors*/
					self.statesMonitor.set(alert: error)
					self.statesMonitor.state = .uninitialized
				}
			}
		case .running:
			/* Toggle back from running to ready */
			moveSDK.stopAutomaticDetection()
			self.isSDKStarted = false
		case .ready:
			/* Toggle to running the SDK services */
			moveSDK.startAutomaticDetection()
			self.isSDKStarted = true
		}
	}

	func resolveErrors() {
		moveSDK.resolveSDKStateError()
	}

	/// Registers a user if not already registered.
	func registerUserIfNeeded(completion: @escaping (Result<MoveAuth, Error>)->()){
		if let auth = auth {
			completion(.success(auth))
		} else {
			/* create a random 7 digits user id*/
			let userID = Int(Date().timeIntervalSince1970).description.prefix(10).description
	
			/* register user and fetch token*/
			Auth.registerSDKUser(userID: userID) { result in
				switch result {
				case let .success(auth):
					/* update state monitor with new id for UI*/
					self.statesMonitor.set(contractID: userID)

					self.auth = auth
				case .failure(_):
					break
				}

				DispatchQueue.main.async {
					completion(result)
				}
			}
		}
	}

	
	/**
	MOVE SDK initialization.
	
	# Tasks
	
	 1. Sets up MOVE SDK listeners
	 2. Prepare MOVE SDK Configurations
	 3. initialize the SDK's shared instance using `initialize` API
	*/
	func initializeSDK(auth: MoveAuth, launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) {

		/* 2.  setup config for allowed SDK services.
		N.B: Requesting services which are not active on the licensed endpoint will result in config mismatch */
		let config = MoveConfig(detectionService: [.driving([.drivingBehavior, .distractionFreeDriving]), .cycling, .walking([.location]), .places, .publicTransport, .pointsOfInterest])

		/* 3. Initialize the SDK's shared instance */
		moveSDK.setup(auth: auth, config: config)
	}

	/// Triggers the SDK internal upload queue and reports network errors on failure
	func performFetch(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		moveSDK.performBackgroundFetch { result in
			completionHandler(result)
		}
	}
}

//MARK:- MOVE SDK Listeners
extension SDKManager {
	
	/**
	Monitors MOVE SDK generated logs.
	Host apps could append those logs to his app analytics or logging tools.
	*/
	func sdkLogListener(_ text: String, _ value: String?) {
		DispatchQueue.main.async {
			self.statesMonitor.logMessage = text
		}
	}

	/// Monitors MOVE SDK Serrvice Warnings
	func sdkWarningListener(_ warnings: [MoveServiceWarning]) {
		DispatchQueue.main.async {
			self.statesMonitor.warnings = warnings
		}
	}

	/// Monitors MOVE SDK Serrvice Failures
	func sdkFailureListener(_ failures: [MoveServiceFailure]) {
		DispatchQueue.main.async {
			self.statesMonitor.failures = failures
		}
	}

	/// Monitors MOVE SDK Auth State and handles the changes accordingly.
	func sdkAuthStateListener(_ state: MoveAuthState) {
		DispatchQueue.main.async {
			self.statesMonitor.authState = "\(state)"
		}

		switch state {
		case .invalid:
			/* the SDK Failed to refresh the current MOVEAuth because it was invalidated */
			self.moveSDK.shutDown()
		default:
			break
		}
	}

	/// Monitors MOVE SDK  State and handles the changes accordingly.
	func sdkStateListener(_ state: MoveSDKState) {
		/* the SDK state listener handles changes in the SDK state machine */
		DispatchQueue.main.async {
			self.statesMonitor.state = state
		}
	}

	/// Monitors MOVE SDK Trip State.
	func sdkTripStateListener(_ state: MoveTripState) {
		/* this is called when the trip state changes */
		/* idle, driving */
		DispatchQueue.main.async {
			self.statesMonitor.tripState = "\(state)"
		}
	}
}
