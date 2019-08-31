//
//  InterphoneSensorDeviceCodable.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/15.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation
import CoreBluetooth

class InterphoneSensorDeviceCodable: NSObject, Codable {
	let peripheralId: String
//	let deviceName: String
//	var modelName: String?
	var nickname: String?
	var mac: String?
//	var threshold: UInt16
//	var maxThreshold: UInt16
//	var minThreshold: UInt16
	var enableConnect: Bool
	
	init(peripheralId: String, nickname: String? = nil, mac: String? = nil, enableConnect: Bool = true) {
		self.peripheralId = peripheralId
		self.nickname = nickname
		self.mac = mac
		self.enableConnect = enableConnect
	}
	
	init(withDevice device: InterphoneSensorDevice) {
		peripheralId = device.peripheralId
		nickname = device.nickname
		mac = device.mac
		enableConnect = device.enableConnect
	}
}
