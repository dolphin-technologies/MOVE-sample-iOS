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

struct CellView: View {
	
	@Binding var toggle: Bool
	@Binding var disabled: Bool

	let currentStateRecordingBGColor = Color.init(r: 243, g: 243, b: 243)

	var title: String
	var description: String

	
    var body: some View {
		VStack(alignment: .leading) {
			HStack {
				Text(title)
					.font(.system(size: 16, weight: .semibold))
					.padding([.leading, .top])
				Toggle("", isOn: $toggle)
					.padding([.trailing, .top])
					.disabled(disabled)
			}
			Capsule()
				.frame(idealWidth: .infinity, minHeight: 1, maxHeight: 1)
				.foregroundColor(Color.white)
				.padding(.bottom, 5)
			Text(description)
				.font(.caption)
				.foregroundColor(.gray)
				.padding([.horizontal, .bottom])
				.fixedSize(horizontal: false, vertical: true)
		}
		.background(currentStateRecordingBGColor)
		.cornerRadius(15.0)
		.padding(.horizontal)
		.onTapGesture {
			if disabled {
				UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
			}
		}

    }
}

struct CellView_Previews: PreviewProvider {
    static var previews: some View {
		CellView(toggle: .constant(true), disabled: .constant(false), title: "Location", description: "MOVE needs the location permission to track user trips and activities.")
    }
}
