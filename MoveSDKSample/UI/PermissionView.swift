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

struct PermissionView: View {

	@StateObject var locationPermission: LocationPermission
	@StateObject var motionPermission: MotionPermission

	var body: some View {
		VStack {
			Text("PERMISSIONS")
				.font(.system(size: 20, weight: .semibold))
				.padding(.horizontal)
			Text("MOVE needs the following permissions to record your activities. Please check each one and grant them.")
				.fixedSize(horizontal: false, vertical: true)
				.padding(.horizontal)
				.padding(.vertical, 2)
				.foregroundColor(.black).opacity(0.7)
				.font(.footnote)

			CellView(toggle: $locationPermission.isAllowed, disabled: $locationPermission.isDisabled, title: "LOCATION", description: "MOVE needs the location permission to track user trips and activities.")

			CellView(toggle: $motionPermission.isAllowed, disabled: $motionPermission.isDisabled, title: "MOTION", description: "MOVE needs the motion permission in order to record walking activities. Please grant access to your fitness & motion data.")
		}
	}
}

struct PermissionView_Previews: PreviewProvider {
	static var previews: some View {
		PermissionView(locationPermission: LocationPermission(), motionPermission: MotionPermission())
	}
}
