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
		didSet{
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
			if let contractID = auth?.contractID {
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
	func initSDKIfPossible(withOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) {
		if let auth = auth {
			initializeSDK(auth: auth, launchOptions: options)
		}
	}

	/// Toggles MOVE SDK Activation State
	func toggleMoveSDKState() {
		
		/* Toggle SDK State */
		isSDKStarted = !isSDKStarted
		
		/* Switch on latest state to determine the action */
		switch moveSDK.getSDKState() {
		case .uninitialized:
			registerUserIfNeeded { auth in
				if let auth = auth {
					self.initializeSDK(auth: auth)
				}
				else {
					
					/* Inform the monitor with the errors*/
					self.statesMonitor.set(alert: .networkError)
					
					/* revert isSDKStarted user setting on registration failure */
					self.isSDKStarted = false
					self.statesMonitor.sdkState = .uninitialized
				}
			}
		case .running:
			/* Toggle back from running to ready */
			moveSDK.stopAutomaticDetection()
		case .ready:
			/* Toggle to running the SDK services */
			moveSDK.startAutomaticDetection()
		default: break
		}
	}

	/// Registers a user if not already registered.
	func registerUserIfNeeded(completion: @escaping (MoveAuth?)->()){
		if let auth = auth {
			completion(auth)
		} else {
			/* create a random 7 digits user id*/
			let userID = Int(Date().timeIntervalSince1970).description.prefix(10).description
	
			/* register user and fetch token*/
			Auth.registerSDKUser(userID: userID) { auth in
				if let auth = auth {
					/* update state monitor with new id for UI*/
					self.statesMonitor.set(contractID: userID)
					
					self.auth = auth
					DispatchQueue.main.async {
						completion(auth)
					}
				}
				else {
					DispatchQueue.main.async {
						completion(nil)
					}
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
		
		/* 1. setup listeners for the SDK callbacks */
		moveSDK.setLogListener(sdkLogListener)
		moveSDK.setAuthStateUpdateListener(sdkAuthStateListener)
		moveSDK.setSDKStateListener(sdkStateListener)
		moveSDK.setTripStateListener(sdkTripStateListener)

		/* 2.  setup config for allowed SDK services.
		N.B: Requesting services which are not active on the licensed endpoint will result in config mismatch */
		let config = MoveConfig(timelineDetectionService: [.driving, .bicycle, .walking], drivingServices: [.dfd, .behaviour], otherServices: [.poi])

		/* 3. Initialize the SDK's shared instance */
		moveSDK.initialize(auth: auth, config: config, launchOptions: launchOptions) { error in
			DispatchQueue.main.async {
				if let error = error {
					
					/* revert isSDKStarted user setting on start failure */
					self.isSDKStarted = false
				
					/* config mismatch or network/gateway errors */
					switch error {
					case .configMismatch:
						self.statesMonitor.set(alert: .configError)
					case .serviceUnreachable:
						self.statesMonitor.set(alert: .networkError)
					default:
						break
					}
				}
				
			}
		}
	}
}

//MARK:- MOVE SDK Listeners
extension SDKManager {
	
	/**
	Monitors MOVE SDK generated logs.
	Host apps could append those logs to his app analytics or logging tools.
	*/
	func sdkLogListener(_ text: String) {
		DispatchQueue.main.async {
			self.statesMonitor.logMessage = text
		}
	}

	/// Monitors MOVE SDK Auth State and handles the changes accordingly.
	func sdkAuthStateListener(_ state: MoveAuthState) {
		DispatchQueue.main.async {
			self.statesMonitor.authState = "\(state)"
		}

		switch state {
		case let .valid(auth):
			/* store the newly refreshed MOVEAuth to use on next init */
			self.auth = auth
		case .expired:
			/* the SDK Failed to refresh the current MOVEAuth and needs a new MOVEAuth key */
			self.fetchAndUpdateSDKAuth()
		case .unknown:
			/* initial state, ignore */
			break
		@unknown default:
			break
		}
	}

	/// Monitors MOVE SDK  State and handles the changes accordingly.
	func sdkStateListener(_ state: MoveSDKState) {
		/* the SDK state listener handles changes in the SDK state machine */
		DispatchQueue.main.async {
			self.statesMonitor.sdkState = state
		}

		switch state {
		case .running, .uninitialized: break
		case .ready:
			/* skip ready state and start service if it was not transiting from running state */
			if isSDKStarted {
				self.moveSDK.startAutomaticDetection()
			}
		case .error:
			/* the app needs to handle permission errors, which requires user interaction */
			/* the SDK should go back to '.ready' state once these are resolved */
			break
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

//MARK:- Authorization
extension SDKManager {
	/**
	Refetch new SDK Auth object and update the SDK.
	
	# Tasks
	
	 1. fetch new SDK Auth
	 2. persist it
	 3. update the SDK with the new Auth using`update(auth: MoveAuth)` API
	*/
	func fetchAndUpdateSDKAuth() {
		guard let auth = auth else { return }

		/* to get new refresh/access token use register function */
		Auth.registerSDKUser(userID: auth.contractID) { auth in
			if let auth = auth {
				self.auth = auth
				self.moveSDK.update(auth: auth) { error in
					if let error = error {
						print("\(error)")
						/* the app is responsible for further error handling as of here */
						/* maybe config mismatched */
						/* retry or notify user ... */
					}
				}
			} else {
				/* the app is responsible for further error handling as of here */
				/* retry or notify user ... */
			}
		}
	}
}
