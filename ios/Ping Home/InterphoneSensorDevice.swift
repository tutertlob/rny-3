//
//  InterphoneSensorDevice.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/02.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation
import CoreBluetooth

class InterphoneSensorDevice: NSObject {
	private let _codable: InterphoneSensorDeviceCodable
	var sensingCharacteristic: CBCharacteristic?
	var thresholdCharacteristic: CBCharacteristic?
	var syncEpochTimeCharacteristic: CBCharacteristic?
	var pingPongRecordCharacteristic: CBCharacteristic?
	var deleteRecordCharacteristic: CBCharacteristic?
	
	var codable: InterphoneSensorDeviceCodable {
		get {
//			_codable.modelName = modelName
//			_codable.nickname = nickname
//			_codable.mac = mac
//			_codable.threshold = threshold
//			_codable.maxThreshold = maxThreshold
//			_codable.minThreshold = minThreshold
//			_codable.enableConnect = enableConnect
//			return _codable
			_codable.nickname = nickname
			_codable.mac = mac
			_codable.enableConnect = enableConnect
			return _codable
		}
	}
	let peripheralId: String
	var deviceName: String
	var modelName: String?
	var nickname: String?
	var mac: String?
	var threshold: UInt16
	var maxThreshold: UInt16
	var minThreshold: UInt16
	var enableConnect: Bool
	var peripheral: CBPeripheral?
	var isConnected: Bool {
		if let state = peripheral?.state {
			return state == CBPeripheralState.connected
		} else {
			return false
		}
	}
	
	init(withCodableDevice device: InterphoneSensorDeviceCodable) {
		
		_codable = device
		peripheralId = device.peripheralId
		deviceName = ""
		modelName = nil
		nickname = device.nickname
		mac = device.mac
		threshold = 500
		maxThreshold = 65535
		minThreshold = 0
		enableConnect = device.enableConnect
		peripheral = nil
		super.init()
	}

	init(peripheralId: String, deviceName: String, modelName: String? = nil, nickname: String?, mac: String? = nil, threshold: UInt16 = 500, maxThreshold: UInt16 = 65535, minThreshold: UInt16 = 0, enableConnect: Bool = true, peripheral: CBPeripheral? = nil) {
		self.peripheralId = peripheralId
		self.deviceName = deviceName
		self.modelName = modelName
		self.nickname = nickname ?? deviceName
		self.mac = mac
		self.threshold = threshold
		self.maxThreshold = maxThreshold
		self.minThreshold = minThreshold
		self.enableConnect = enableConnect
		self.peripheral = peripheral

		_codable = InterphoneSensorDeviceCodable(peripheralId: peripheralId, nickname: nickname, mac: mac, enableConnect: enableConnect)


		super.init()
	}
}
