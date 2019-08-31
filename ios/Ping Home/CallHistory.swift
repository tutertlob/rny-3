//
//  CallHistory.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/16.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation

struct CallHistory: Codable, Equatable {
	let text: String
	let timeOfCall: String
	let date: Date
	private static let message: String = "来訪がありました"
	private static let formatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMdyHms", options: 0, locale: Locale(identifier: "ja_JP"))
		return formatter
	}()
	
	init() {
		text = CallHistory.message
		date = Date()
		timeOfCall = CallHistory.formatter.string(from: date)
	}
	
	init(withTimeOfCall date: Date) {
		text = CallHistory.message
		self.date = date
		timeOfCall = CallHistory.formatter.string(from: date)
	}
	init(withTitle text: String, timeOfCall date: Date) {
		self.text = text
		self.date = date
		timeOfCall = CallHistory.formatter.string(from: date)
	}
	
	public static func == (lhs: CallHistory, rhs: CallHistory) -> Bool {
		return lhs.date == rhs.date
	}
}
