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

struct StateLabel: Identifiable {
	var id = UUID()
	
	let title: String
	@Binding var value: String
}


struct StateView: View {
	let currentStateRecordingBGColor = Color(r: 243, g: 243, b: 243)
	var states: [StateLabel]

	var body: some View {
		VStack(alignment: .center, spacing: 5) {
			Rectangle()
				.frame(maxWidth: .infinity, maxHeight: .infinity)
				.foregroundColor(Color.clear)
			ForEach(states) { state in
				HStack {
					Text(state.title)
						.font(.system(size: 12, weight: .bold))
					Text(state.value)
						.font(.system(size: 12))
				}
			}
			
		}
		.frame(maxWidth: .infinity)
		.padding(.top, 10)
		.padding(.bottom, 20)
		.background(currentStateRecordingBGColor)
	}
}

struct StateView_Previews: PreviewProvider {
	static var previews: some View {
		StateView(states: [StateLabel(title: "SDK STATE:", value: .constant("-")), StateLabel(title: "SDK TRIP STATE:", value: .constant("-")),  StateLabel(title: "SDK AUTH STATE:", value: .constant("-"))])
	}
}
