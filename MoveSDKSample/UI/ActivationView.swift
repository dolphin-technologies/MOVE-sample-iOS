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

struct ActivationView: View {
	@StateObject var viewModel: ViewModel

    var body: some View {
		VStack {
			ZStack {
				LinearGradient(gradient: Gradient(colors: [viewModel.currentStateBGColor1, viewModel.currentStateBGColor2]), startPoint: .top, endPoint: .bottom)
				VStack(alignment: .leading) {
					Text("CURRENT STATE")
						.font(.headline)
						.fontWeight(.heavy)
						.foregroundColor(.white)
						.padding([.horizontal])
						.padding(.bottom, 5)

					CellView(toggle: $viewModel.activationToggle, disabled: .constant(false), title: viewModel.title, description: viewModel.sdkListeners.contractID)
				}
				.padding(.vertical)
			}
		}
    }
}

struct ActivationView_Previews: PreviewProvider {
    static var previews: some View {
		ActivationView(viewModel: ViewModel())
    }
}
