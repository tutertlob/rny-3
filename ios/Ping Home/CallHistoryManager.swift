//
//  CallHistoryManager.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/22.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation

class CallHistoryManager {
	static let sharedInstace: CallHistoryManager = {
		let manager = CallHistoryManager()
		
		guard let json = UserDefaults.standard.object(forKey: Keys.pingPongHistories.rawValue) as? String else {
			return manager
		}
		
		guard let jsonData = json.data(using: String.Encoding.utf8) else {
			return manager
		}
		
		let jsonDecoder = JSONDecoder()
		list = try! jsonDecoder.decode([CallHistory].self, from: jsonData)
		
		return manager
	}()
	
	enum Keys: String {
		case pingPongHistories
	}
	
	private static var list: [CallHistory] = []

	var callHistories: [CallHistory] {
		get {
			return CallHistoryManager.list.reversed()
		}
	}

	var beginTime: UInt32 {
		get {
			guard let lastHistory = CallHistoryManager.list.first else {
				return 0
			}
			
			let beginTime = UInt32(lastHistory.date.timeIntervalSince1970)
			return beginTime
		}
	}
	
	var lastTime: UInt32 {
		get {
			guard let lastHistory = CallHistoryManager.list.last else {
				return 0
			}
			
			let lastTime = UInt32(lastHistory.date.timeIntervalSince1970)
			return lastTime
		}
	}
	
	static func storePingPongHistories() {
		let jsonEncoder = JSONEncoder()
		let jsonData = try! jsonEncoder.encode(CallHistoryManager.list)
		let json = String(bytes: jsonData, encoding: String.Encoding.utf8)!
		UserDefaults.standard.set(json, forKey: Keys.pingPongHistories.rawValue)
		UserDefaults.standard.synchronize()
	}
	
	func append(_ timestamp: UInt32) {

		let last = lastTime
		let candidate = Date(timeIntervalSince1970: Double(timestamp))
		
		if last < timestamp {
			CallHistoryManager.list.append(CallHistory(withTimeOfCall: candidate))
		} else if beginTime > timestamp {
			CallHistoryManager.list.insert(CallHistory(withTimeOfCall: candidate), at: 0)
		} else {
//			let index = list.firstIndex(where: {
//				let candidate = Date(timeIntervalSince1970: Double(timestamp))
//				if $0.date > candidate {
//					return true
//				} else {
//					return false
//				}
//			})
			for (index, element) in CallHistoryManager.list.enumerated() {
				if element.date > candidate {
					let candidate = Date(timeIntervalSince1970: Double(timestamp))
					CallHistoryManager.list.insert(CallHistory(withTimeOfCall: candidate), at: index)
					break
				} else if element.date == candidate {
					break
				}
			}
		}
		if CallHistoryManager.list.count > 20 {
			CallHistoryManager.list.removeFirst()
		}
	}
	
	func remove(timestamp: Date) {
		if let index = CallHistoryManager.list.firstIndex(where: {
			return $0.date == timestamp
		}) {
			CallHistoryManager.list.remove(at: index)
		}
	}
	
	private init() {
		
	}
	
	static func end() {
		storePingPongHistories()
	}
}
