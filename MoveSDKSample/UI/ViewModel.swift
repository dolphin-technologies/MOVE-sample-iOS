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

import Foundation
import Combine
import SwiftUI
import DolphinMoveSDK

class ViewModel: ObservableObject {
	
	struct Warning: Hashable {
		let service: String
		let reasons: [String]
	}
	
	/// Instance of the SDKStatesMonitor to track SDK states changes
	@ObservedObject var sdkListeners: SDKStatesMonitor = SDKManager.shared.statesMonitor
	
	/// Current activation view title
	@Published var title: String = "NOT RECORDING"
	
	/// Current sdk state string
	@Published var currentSDKStateLabel: String = "uninitialized"

	/// Current activation view background color 1
	@Published var currentStateBGColor1: Color = Color.stateShutdownBGColor1
	
	/// Current activation view background color 2
	@Published var currentStateBGColor2: Color = Color.stateShutdownBGColor2
	
	/// current error display state
	@Published var showAlert: Bool = false

	@Published var warnings: [Warning] = []

	@Published var failures: [Warning] = []

	/// Forwards SDKStatesMonitor changes to UI
	private var sdkStatesListener: AnyCancellable? = nil

	/// Intercept SDK warnings
	private var sdkWarningsListener: AnyCancellable? = nil

	/// Intercept SDK failures
	private var sdkFailuresListener: AnyCancellable? = nil

	/// Intercept SDK activation state changes to reflect on UI variables
	private var sdkActivationStateInterceptor: AnyCancellable? = nil
	
	/// Intercept errors  to reflect on UI in a toast view
	private var errorsInterceptor: AnyCancellable? = nil
	
	/// Allows UI to toggle activation state
	@Published var activationToggle: Bool = SDKManager.shared.isSDKStarted {
		willSet {
			if newValue != activationToggle {
				SDKManager.shared.toggleMoveSDKState()
			}
		}
	}
	
	init() {
		/* Forwards SDKStatesMonitor changes to UI */
		sdkStatesListener = sdkListeners.objectWillChange.sink { [weak self] (_) in
			guard let self = self else {return}
			DispatchQueue.main.async {
				self.objectWillChange.send()
			}
		}
		
		/* Track SDK state to set UI variables */
		sdkActivationStateInterceptor = sdkListeners.$state.sink(receiveValue: { newValue in
			DispatchQueue.main.async {
				switch newValue {
				case .uninitialized, .ready:
					self.currentStateBGColor1 = Color.stateShutdownBGColor1
					self.currentStateBGColor2 = Color.stateShutdownBGColor2
				case .running:
					self.currentStateBGColor1 = Color.stateRunningBGColor1
					self.currentStateBGColor2 = Color.stateRunningBGColor2
				}
				self.setActivationTitleFor(state: newValue)
				self.setSDKTitleFor(state: newValue)
			}
		})

		sdkWarningsListener = sdkListeners.$warnings.sink {
			var warnings: [Warning] = []
			for warning in $0 {
				let service = warning.service.debugDescription
				var reasons: [String] = []
				switch warning.reason {
				case let .missingPermission(permissions):
					reasons = permissions.map { "\($0)" }
				}
				warnings.append(Warning(service: service, reasons: reasons))
			}
			DispatchQueue.main.async {
				self.warnings = warnings
			}
		}

		sdkFailuresListener = sdkListeners.$failures.sink {
			var warnings: [Warning] = []
			for warning in $0 {
				let service = warning.service.debugDescription
				var reasons: [String] = []
				switch warning.reason {
				case let .missingPermission(permissions):
					reasons = permissions.map { "\($0)" }
				case .unauthorized:
					reasons = ["unauthorized"]
				}
				warnings.append(Warning(service: service, reasons: reasons))
			}
			DispatchQueue.main.async {
				self.failures = warnings
			}
		}


		/* Track error to set UI toast alert  */
		errorsInterceptor = sdkListeners.$alertError.sink(receiveValue: { newValue in
			DispatchQueue.main.async {
				self.showAlert = !newValue.isEmpty
			}
		})
	}
	
	/// Sets ActivationView title based on passed MoveSDKState
	func setActivationTitleFor(state: MoveSDKState) {
		switch state {
		case .uninitialized, .ready:
			self.title = "NOT RECORDING"
		case .running:
			self.title = "RECORDING"
		}
	}
	
	/// Sets ActivationView title based on passed MoveSDKState
	func setSDKTitleFor(state: MoveSDKState) {
		self.currentSDKStateLabel = "\(state)"
	}

	func string(permission: MovePermission) -> String {
		switch permission {
		case .location:
			return "location permission missing"
		case .backgroundLocation:
			return "background location missing"
		case .preciseLocation:
			return "location precision missing"
		case .motionActivity:
			return "motion permission missing"
		default:
			return "sensors missing"
		}
	}
}

extension Color {
	static var stateRunningBGColor1 = Color(r: 190, g: 233, b: 105)
	static var stateRunningBGColor2 = Color(r: 90, g: 145, b: 50)

	static var stateNotRunningBGColor1 = Color(r: 255, g: 255, b: 136)
	static var stateNotRunningBGColor2 = Color(r: 255, g: 250, b: 187)
	static var stateNotRunningBGColor3 = Color(r: 255, g: 187, b: 136)

	static var stateShutdownBGColor1 = Color(r: 243, g: 80, b: 94)
	static var stateShutdownBGColor2 = Color(r: 160, g: 5, b: 28)
}
