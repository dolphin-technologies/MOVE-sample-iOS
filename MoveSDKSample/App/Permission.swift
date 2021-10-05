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

import SwiftUI

import CoreLocation
import CoreMotion

class Permission: ObservableObject {

	/// Flag representing if permission toggle is disabled.
	@Published var isDisabled: Bool = false

	/// Flag bind to permission toggle and triggers permission request.
	@Published var isAllowed: Bool = false {
		willSet {
			if newValue != isGranted {
				requestPermission()
			}
		}
	}
	
	/// Internal flag representing  permission status
	@Published fileprivate var isGranted: Bool = false {
		didSet {
			isAllowed = isGranted
		}
	}

	fileprivate func requestPermission() {}
}

class LocationPermission: Permission {

	class Delegate: NSObject, CLLocationManagerDelegate {
		weak var delegate: LocationPermission?

		func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
			delegate?.getLocationPermission()
		}
	}

	private let locationManager = CLLocationManager()
	private let locationManagerDelegate = Delegate()

	override init() {
		super.init()
		locationManagerDelegate.delegate = self
		locationManager.delegate = locationManagerDelegate
		getLocationPermission()
	}

	override fileprivate func requestPermission() {
		print("request location")
		locationManager.requestAlwaysAuthorization()
	}

	private func getLocationPermission() {
		let isPrecise: Bool
		let status: CLAuthorizationStatus

		if #available(iOS 14, *) {
			isPrecise = locationManager.accuracyAuthorization == .fullAccuracy ? true : false
			status = locationManager.authorizationStatus
		} else {
			isPrecise = true
			status = CLLocationManager.authorizationStatus()
		}

		switch status {
		case .notDetermined:
			isGranted = false
			isDisabled = false
		case .restricted:
			isGranted = false
			isDisabled = true
		case .denied:
			isGranted = false
			isDisabled = true
		case .authorizedAlways:
			isGranted = true
			isDisabled = true
		case .authorizedWhenInUse:
			isGranted = true
			isDisabled = true
		@unknown default:
			isGranted = false
			isDisabled = false
		}
	}
}

class MotionPermission: Permission {

	let motionManager = CMMotionActivityManager()

	/**
	Represents if motion permission has been requested before by the user.
	
	As the only technique to check for the motion permission status, also triggers requesting the motion permission itself; evaluating the motion permission status in the `init()` would trigger the permission. Hence this flag is used in the `init()`  function to determine if the permission has been asked before or not and prevent triggering the permission on the first app initialisation.
	*/
	private var isPermissionRequested: Bool
	
	/// Is motion permission requested User defaults key
	private let isPermissionRequestedKey = "isMotionPermissionRequested"
	
	
	override init() {
		
		isPermissionRequested = UserDefaults.standard.bool(forKey: isPermissionRequestedKey)

		super.init()

		if isPermissionRequested {
			requestMotionPermission() { status in
				self.get(status: status)
			}
		}
	}

	override fileprivate func requestPermission() {
		isPermissionRequested = true
		UserDefaults.standard.set(isPermissionRequested, forKey: isPermissionRequestedKey)
		requestMotionPermission() { status in
			self.get(status: status)
		}
	}

	private func requestMotionPermission(_ completion: ((_ result: CMAuthorizationStatus) -> Void)? = nil) {

		motionManager.queryActivityStarting(from: Date(), to: Date(), to: OperationQueue.main) { _, error in			
			if let _ = error {
				
				//TODO: handle simulator case
				/* Check if permission is granted on simulator to bypass sensors not available error .*/
//				let cmError = CMError(rawValue: UInt32((error as NSError).code))
//				if cmError == CMErrorMotionActivityNotAvailable {
//					completion?(CMAuthorizationStatus.authorized)
//				}
//				else {
					completion?(CMAuthorizationStatus.denied)
				//}
			}
			else {
				completion?(CMAuthorizationStatus.authorized)
			}
		}
	}

	private func get(status: CMAuthorizationStatus) {
		switch status {

		case .notDetermined:
			isGranted = false
			isDisabled = false
		case .restricted:
			isGranted = false
			isDisabled = true
		case .denied:
			isGranted = false
			isDisabled = true
		case .authorized:
			isGranted = true
			isDisabled = true
		@unknown default:
			isGranted = false
			isDisabled = false
		}
	}
}
