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
import DolphinMoveSDK

enum AuthError: Error, LocalizedError {
	case configError(String)
	case networkError(String)

	public var errorDescription: String? {
		switch self {
		case let .configError(text):
			return "\(text)"
		case let .networkError(text):
			return "Network Error: '\(text)'."
		}
	}
}

struct Auth: Codable {
	struct Response: Decodable {
		let authCode: String
	}

	let accessToken: String
	let refreshToken: String
	let userId: String
	let projectId: Int

	static func getConfig() -> [String: String] {
		if let path = Bundle.main.url(forResource: "Configuration", withExtension: "plist"),
		   let data = try? Data(contentsOf: path),
		   let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: String] {
			return dict
		}
		return [:]
	}

	static func registerSDKUser(userID: String, completion: @escaping((Result<String, Error>)->())) {
		guard let bearer = getConfig()["Bearer"], !bearer.isEmpty else {
			/* Bearer is the API key for authenticating with the the Move SDK.
			 * You must add the API key in 'Configuration.plist'
			 * The API key is obtained from the MOVE Dashboard. https://dashboard.movesdk.com/admin/sdkConfig/keys
			 */
			completion(.failure(AuthError.configError("Missing API key.\nSee 'README.md'.")))
			return
		}

		let session = URLSession.shared
		var components = URLComponents(string: "https://sdk.dolph.in/v20/user/authcode")!
		components.queryItems = [
			URLQueryItem(name: "userId", value: userID)
		]
		var request = URLRequest(url: components.url!)
		request.addValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")

		request.httpMethod = "GET"
		request.addValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

		let task = session.dataTask(with: request) { (data, response, error) in
			if let error = error {
				completion(.failure(error))
			}
			else if let data = data {
				let text = String(data: data, encoding: .utf8) ?? "unknown"
				let obj = try? JSONDecoder().decode(Auth.Response.self, from: data)
				if let code = obj?.authCode {
					completion(.success(code))
				} else {
					completion(.failure(AuthError.networkError(text)))
				}
			}
		}
		task.resume()
	}
}
