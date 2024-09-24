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

import AlertToast
import SwiftUI

extension Color {
	init(r: Double, g: Double, b: Double) {
		self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0)
	}
}


struct Dashboard: View {
	@StateObject var locationPermission = LocationPermission()
	@StateObject var motionPermission = MotionPermission()
	@StateObject var viewModel: ViewModel = ViewModel()

	@State private var showGreeting = true

	init() {
		let appearance = UINavigationBarAppearance()
		appearance.configureWithOpaqueBackground()
		appearance.backgroundColor = UIColor(red: 7.0/255.0, green: 18.0/255.0, blue: 48.0/255.0, alpha: 1.0)
		appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
		UINavigationBar.appearance().standardAppearance = appearance
		UINavigationBar.appearance().scrollEdgeAppearance = appearance
	}


	var body: some View {
		NavigationView {
			VStack(alignment: .leading) {
				ActivationView(viewModel: viewModel).frame(height: 167.715)
			GeometryReader { reader in
					ScrollView() {
						VStack(alignment: .leading) {
							WarningsView(viewModel: viewModel)
							PermissionView(locationPermission: locationPermission, motionPermission: motionPermission)
							StateView(states: [StateLabel(title: "SDK STATE:", value: $viewModel.currentSDKStateLabel), StateLabel(title: "SDK TRIP STATE:", value: $viewModel.sdkListeners.tripState),  StateLabel(title: "SDK AUTH STATE:", value: $viewModel.sdkListeners.authState)])
						}
//						.frame(height: reader.size.height)
					}
				}
			}
			.ignoresSafeArea(.all, edges: .bottom)
			.navigationBarTitle("MOVE.", displayMode: .inline)
		}
		.allowsHitTesting(!viewModel.isLoading)
		.toast(isPresenting: $viewModel.showAlert) {
			AlertToast(displayMode: .hud, type: .error(.red), title: "Error", subTitle: viewModel.sdkListeners.alertError)
		}
		.toast(isPresenting: $viewModel.isLoading) {
			AlertToast(type: .loading)
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		Dashboard()
	}
}
