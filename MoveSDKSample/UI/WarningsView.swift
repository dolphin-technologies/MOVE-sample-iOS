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
import DolphinMoveSDK

struct WarningsView: View {
	@StateObject var viewModel: ViewModel

	var body: some View {
		VStack(alignment: .leading) {
			ForEach(viewModel.failures, id: \.self) { warning in
				VStack(alignment: .leading) {
					Text(warning.service)
					Text(warning.reasons.joined(separator: ", "))
				}
				.foregroundColor(.red)
				.font(.footnote.weight(.bold))
				.padding(.vertical, 2)
				.padding(.horizontal)
			}
			ForEach(viewModel.warnings, id: \.self) { warning in
				VStack(alignment: .leading) {
					Text(warning.service)
					Text(warning.reasons.joined(separator: ", "))
				}
				.foregroundColor(.yellow)
				.font(.footnote.weight(.bold))
				.padding(.vertical, 2)
				.padding(.horizontal)
			}
		}
    }
}
