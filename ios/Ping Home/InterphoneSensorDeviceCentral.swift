//
//  BLECentral.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/10.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit
import CoreBluetooth
import UserNotifications

class InterphoneSensorDeviceCentral: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

	static let sharedInstance: InterphoneSensorDeviceCentral = {
		let central = InterphoneSensorDeviceCentral()
		central.loadRegisteredDevices()
		central.centralManager = CBCentralManager(delegate: central, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(booleanLiteral: true)])
		return central
	}()
	
	private enum ServiceUUID: String {
		case primary = "4611a4a6-9b40-11e9-a2a3-2a2ae2dbcce4"
		case secodary = "4611a4a7-9b40-11e9-a2a3-2a2ae2dbcce4"
		case deviceInformation = "180a"
	}
	
	enum CharacteristicUUID: String, CaseIterable {
		case modelNumber = "2a24"
		case serialNumber = "2a25"
		case sensing = "4611ab18-9b40-11e9-a2a3-2a2ae2dbcce4"
		case pingPong = "4611ad5c-9b40-11e9-a2a3-2a2ae2dbcce4"
		case threshold = "4611aec4-9b40-11e9-a2a3-2a2ae2dbcce4"
		case minThreshold = "4611aec5-9b40-11e9-a2a3-2a2ae2dbcce4"
		case maxThreshold = "4611aec6-9b40-11e9-a2a3-2a2ae2dbcce4"
		case syncEpochTime = "4611aec7-9b40-11e9-a2a3-2a2ae2dbcce4"
//		case upperEpochTime = "4611aec8-9b40-11e9-a2a3-2a2ae2dbcce4"
		case pingPongRecord = "4611aec9-9b40-11e9-a2a3-2a2ae2dbcce4"
		case deleteRecord = "4611aeca-9b40-11e9-a2a3-2a2ae2dbcce4"
	}
	
	private enum Keys: String {
		case pingPongDevices
	}
	
	
//	private let connectionOptions: [String: Any]? = [CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(value: true), CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(value: true), CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(value: true)]
	private let connectionOptions: [String: Any]? = [CBConnectPeripheralOptionNotifyOnConnectionKey: NSNumber(booleanLiteral: true), CBConnectPeripheralOptionNotifyOnNotificationKey: NSNumber(booleanLiteral: true), CBConnectPeripheralOptionNotifyOnDisconnectionKey: NSNumber(booleanLiteral: true)]
//	private let connectionOptions: [String: Any]? = nil
//	private var thresholdCharacteristic: CBCharacteristic?
//	private var syncEpochTimeCharacteristic: CBCharacteristic?
//	private var pingPongRecordCharacteristic: CBCharacteristic?
	
	private var centralManager:CBCentralManager?
	private var dictionaryDeviceAndPeripheral: [UUID: (interphone: InterphoneSensorDevice, peripheral: CBPeripheral?, isRegistered: Bool)] = [:]
	private var isChanged: Bool = false
	
	var delegate = MulticastDelegate<InterphoneSensorDeviceDelegate>()
	var registeredDeviceList: [InterphoneSensorDevice] = []
	var unregisteredDeviceList: [InterphoneSensorDevice] = []
	var isScanning: Bool {
		return centralManager?.isScanning ?? false
	}
	var isPowerOn: Bool {
		return centralManager?.state == CBManagerState.poweredOn
	}
	
	private func registerDevice(_ device: InterphoneSensorDevice) {
		if let index = unregisteredDeviceList.firstIndex(where: { $0.peripheralId == device.peripheralId }) {

			isChanged = true
			
			unregisteredDeviceList.remove(at: index)
			registeredDeviceList.append(device)

			if let uuid = UUID(uuidString: device.peripheralId) {
				dictionaryDeviceAndPeripheral[uuid]?.isRegistered = true
			}

			connectWithCheckingCondition(withDevice: device)

			delegate |> { $0.bleCentral?(didUpdateDeviceListFor: self) }
		}
	}
	
	private func unregisterDevice(_ device: InterphoneSensorDevice) {
		if let index = registeredDeviceList.firstIndex(where: { $0.peripheralId == device.peripheralId }) {
			
			isChanged = true
			
			registeredDeviceList.remove(at:index)
			if let uuid = UUID(uuidString: device.peripheralId) {
				dictionaryDeviceAndPeripheral[uuid]?.isRegistered = false
			}
			unregisteredDeviceList.append(device)
			
			if let peripheral = device.peripheral {
				centralManager?.cancelPeripheralConnection(peripheral)
			}
			
			delegate |> { $0.bleCentral?(didUpdateDeviceListFor: self) }

//			print(#function + ": Exit")
		}
	}
	
	private func connectWithCheckingCondition(withDevice device: InterphoneSensorDevice) {

		guard let uuid = UUID(uuidString: device.peripheralId) else {
			return
		}
		guard let element = dictionaryDeviceAndPeripheral[uuid] else {
			return
		}
		
		if device.enableConnect && element.isRegistered && !device.isConnected {
			centralManager?.connect(device.peripheral!, options: connectionOptions)
		}
	}
	
	@objc func didUpdatePreferencesFor(_ notification: Notification) {
//		print(#function)

		guard let device = notification.object as? InterphoneSensorDevice else {
			return
		}
		
		isChanged = true
		
		let data = device.threshold.data
		
		if device.thresholdCharacteristic != nil {
			device.peripheral?.writeValue(data, for: device.thresholdCharacteristic!, type: CBCharacteristicWriteType.withResponse)
		}
		
		if device.enableConnect {
			connectWithCheckingCondition(withDevice: device)
		} else {
			centralManager?.cancelPeripheralConnection(device.peripheral!)
		}
	}
	
	func bleCentral(doRegister device: InterphoneSensorDevice) {
//		print(#function)
		registerDevice(device)
	}

	func bleCentral(doUnregister device: InterphoneSensorDevice) {
//		print(#function)
		unregisterDevice(device)
	}

	func loadRegisteredDevices() {
//		print(#function)
		guard let json = UserDefaults.standard.object(forKey: Keys.pingPongDevices.rawValue) as? String else {
			return
		}
		guard let jsonData = json.data(using: String.Encoding.utf8) else {
			return
		}
		registeredDeviceList.removeAll()
		dictionaryDeviceAndPeripheral.removeAll()
		let jsonDecoder = JSONDecoder()
		let codableRegisteredDeviceList = try! jsonDecoder.decode([InterphoneSensorDeviceCodable].self, from: jsonData)
		codableRegisteredDeviceList.forEach { (codable) in
			let device = InterphoneSensorDevice(withCodableDevice: codable)
			registeredDeviceList.append(device)
			if let uuid = UUID(uuidString: device.peripheralId) {
				if let peripheral = centralManager?.retrievePeripherals(withIdentifiers: [uuid]).first {
//					print("loadRegisterDevices: connect")
					dictionaryDeviceAndPeripheral[uuid] = (interphone: device,  peripheral: peripheral, isRegistered: true)
					connectWithCheckingCondition(withDevice: device)
				} else {
//					print("Append peripheral to dictionaryDeviceAndPeripheral with nill")
					dictionaryDeviceAndPeripheral[uuid] = (interphone: device,  peripheral: nil, isRegistered: true)
				}
			}
		}
	}
	
	func storeRegisteredDevices() {
//		print(#function)
		let codableRegisteredDeviceList = registeredDeviceList.map {
			$0.codable
		}
		let jsonEncoder = JSONEncoder()
		//		jsonEncoder.outputFormatting = JSONEncoder.OutputFormatting.prettyPrinted
		let jsonData = try! jsonEncoder.encode(codableRegisteredDeviceList)
		let json = String(bytes: jsonData, encoding: String.Encoding.utf8)!
		UserDefaults.standard.set(json, forKey: Keys.pingPongDevices.rawValue)
		UserDefaults.standard.synchronize()
	}
	
	func startScanForInterphoneSensors() {
//		print(#function)
		centralManager?.scanForPeripherals(withServices: [CBUUID(string: ServiceUUID.primary.rawValue)], options: nil)
	}
	
	func centralManagerDidUpdateState(_ central: CBCentralManager) {
//		print(#function)
//		print("\(central)")
		switch central.state {
		case .poweredOn:
//			print("poweredOn")
			delegate |> { $0.bleCentral?(didUpdatePowerStateFor: self, powerState: true) }

			startScanForInterphoneSensors()
			delegate |> { $0.bleCentral?(didUpdateScanStateFor: self, scanState: true) }
		case .unknown:
			print("unknown")
		case .resetting:
			print("resetting")
		case .unsupported:
			print("unsupported")
		case .unauthorized:
			print("unauthorized")
		case .poweredOff:
			print("powerOff")
			delegate |> { $0.bleCentral?(didUpdateScanStateFor: self, scanState: false) }
			delegate |> { $0.bleCentral?(didUpdatePowerStateFor: self, powerState: false) }
		@unknown default:
			print("unknown")
		}
	}

	func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
		print(#function)
		
		for key in advertisementData.keys {
			switch key {
			case CBAdvertisementDataLocalNameKey:
				print(advertisementData[key] as! String)
			case CBAdvertisementDataServiceUUIDsKey:
				let uuids = advertisementData[key] as! [CBUUID]
				for uuid in uuids {
					print(uuid)
				}
			case CBAdvertisementDataIsConnectable:
				print(advertisementData[CBAdvertisementDataIsConnectable] as! Bool)
			case CBAdvertisementDataTxPowerLevelKey:
				print(advertisementData[CBAdvertisementDataTxPowerLevelKey] as! NSNumber)
			default:
				print("Un-handled \(key)")
			}
		}
		
		if var element = dictionaryDeviceAndPeripheral[peripheral.identifier] {
			element.interphone.peripheral = peripheral
			if peripheral.name != nil {
				element.interphone.deviceName = peripheral.name!
			}
			element.peripheral = peripheral
			connectWithCheckingCondition(withDevice: element.interphone)
		} else {
			let newDevice = InterphoneSensorDevice(peripheralId: peripheral.identifier.uuidString, deviceName: peripheral.name!, nickname: peripheral.name, peripheral: peripheral)
			unregisteredDeviceList.append(newDevice)
			dictionaryDeviceAndPeripheral[peripheral.identifier] = (interphone: newDevice,  peripheral: peripheral, isRegistered: false)
			delegate |> { $0.bleCentral?(didUpdateDeviceListFor: self) }
		}
	}

	func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
		print("Connected")
		let device = dictionaryDeviceAndPeripheral[peripheral.identifier]!.interphone
		peripheral.delegate = self
		peripheral.discoverServices([CBUUID(string: ServiceUUID.primary.rawValue), CBUUID(string: ServiceUUID.secodary.rawValue), CBUUID(string: ServiceUUID.deviceInformation.rawValue)])
		if !device.enableConnect {
			centralManager?.cancelPeripheralConnection(peripheral)
		} else {
			delegate |> { $0.interphoneSensorDevice?(self, didConnect: device)}
		}
	}

	func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
		print("Disconnected")
		if let element = dictionaryDeviceAndPeripheral[peripheral.identifier] {
			delegate |> { $0.interphoneSensorDevice?(self, didDisconnect: element.interphone)}
			connectWithCheckingCondition(withDevice: element.interphone)
		}
	}

	func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
		print(#function)
	}

	func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
//		print(#function)
	}

	//
	// For handling Peripheral
	//
	func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
//		print(#function)
		for service in peripheral.services! {
//			print("Service: \(service.description)")
			let uuids = CharacteristicUUID.allCases.map {
				CBUUID(string: $0.rawValue)
			}
			peripheral.discoverCharacteristics(uuids, for: service)
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
//		print(#function)
//		print("\(peripheral) for \(service)")
		guard let device = dictionaryDeviceAndPeripheral[peripheral.identifier] else {
			return
		}
		
		for character in service.characteristics! {
//			print("\n\tDiscoverd characteristic: \(character)")
			guard let uuid = CharacteristicUUID(rawValue: character.uuid.uuidString.lowercased()) else {
				continue
			}
			
			switch uuid {
			case CharacteristicUUID.sensing:
				device.interphone.sensingCharacteristic = character
				
			case CharacteristicUUID.pingPong:
				peripheral.setNotifyValue(true, for: character)
				
			case CharacteristicUUID.threshold:
				device.interphone.thresholdCharacteristic = character
				peripheral.readValue(for: character)
				
			case CharacteristicUUID.maxThreshold, CharacteristicUUID.minThreshold, CharacteristicUUID.serialNumber, CharacteristicUUID.modelNumber:
				peripheral.readValue(for: character)
				
			case CharacteristicUUID.syncEpochTime:
				device.interphone.syncEpochTimeCharacteristic = character
				
			case CharacteristicUUID.pingPongRecord:
				device.interphone.pingPongRecordCharacteristic = character
				
			case CharacteristicUUID.deleteRecord:
				device.interphone.deleteRecordCharacteristic = character
				
			}
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
//		print(#function)
//		print("didUpdateNotification: \(characteristic)")
		if error != nil {
			print("Setting notify is incompleted with: \(error!)")
		} else {
			print("Set notify for \(characteristic)")
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
//		print(#function)

		guard error == nil else {
			print("Update value for \(characteristic) failed")
			return
		}
		
		guard let uuid = CharacteristicUUID(rawValue: characteristic.uuid.uuidString.lowercased()) else {
			return
		}
		
		let device = dictionaryDeviceAndPeripheral[peripheral.identifier]!
		switch uuid {
		case CharacteristicUUID.pingPong:
			if characteristic.isNotifying {
				peripheral.setNotifyValue(false, for: characteristic)
//				print("\(characteristic)")
				if let value = characteristic.value?.uint16 {
					print(value)
				}
				Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { (Timer) in
					print("Timer expired")
					if peripheral.state == CBPeripheralState.connected {
						peripheral.setNotifyValue(true, for: characteristic)
					}
				})
				notifyGotVisitor()
				delegate |> { $0.interphoneSensorDevice?(self, didNotifyInterphoneCall: device.interphone) }
			}
		case CharacteristicUUID.threshold:
			device.interphone.threshold = characteristic.value!.uint16
			delegate |> { $0.interphoneSensorDevice?(self, didUpdateValueFor: device.interphone) }
		case CharacteristicUUID.maxThreshold:
			device.interphone.maxThreshold = characteristic.value!.uint16
			delegate |> { $0.interphoneSensorDevice?(self, didUpdateValueFor: device.interphone) }
		case CharacteristicUUID.minThreshold:
			device.interphone.minThreshold = characteristic.value!.uint16
			delegate |> { $0.interphoneSensorDevice?(self, didUpdateValueFor: device.interphone) }
		case CharacteristicUUID.serialNumber:
			if let mac = characteristic.value?.string {
				device.interphone.mac = mac
				delegate |> { $0.interphoneSensorDevice?(self, didUpdateValueFor: device.interphone) }
			}
		case CharacteristicUUID.modelNumber:
			if let model = characteristic.value?.string {
				device.interphone.modelName = model
				delegate |> { $0.interphoneSensorDevice?(self, didUpdateValueFor: device.interphone) }
			}
		case CharacteristicUUID.syncEpochTime:
			if let value = characteristic.value?.uint32 {
				print("epoch time: \(value)")
			}
		case CharacteristicUUID.pingPongRecord:
			if let value = characteristic.value?.uint32 {
				if value == 0 {
					delegate |> { $0.bleCentral?(didUpdatePingPongListFor: self) }
					break
				} else {
					CallHistoryManager.sharedInstace.append(value)
					peripheral.readValue(for: characteristic)
				}
			}

		default:
			print("Unknown: \(characteristic)")
		}
	}

	func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
//		print(#function)
		for desc in characteristic.descriptors! {
//			print("\(characteristic)\n\t\(desc)")
			peripheral.readValue(for: desc)
		}
	}

//	func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
//		print(#function)
//	}

	private override init() {
		super.init()
	}
	
	func begin() {
//		print(#function)

		if centralManager == nil {
			centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: NSNumber(value: true)])
			centralManager?.delegate = self
		}
	}
	
	func end() {
//		print(#function)

		if isChanged {
			storeRegisteredDevices()
		}
		
		if let central = centralManager {
			if central.isScanning {
				central.stopScan()
			}
		}

		let uuids = [UUID](dictionaryDeviceAndPeripheral.keys)
		centralManager?.retrievePeripherals(withIdentifiers: uuids).forEach({ (peripheral) in
			centralManager?.cancelPeripheralConnection(peripheral)
		})
	}
	
	func didEnterForground() {
//		print(#function)

		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.onUnregisterDevice(_:)), name: Notification.Name.onUnregisterDevice, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.onRegisterDevice(_:)), name: Notification.Name.onRegisterDevice, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.didUpdatePreferencesFor(_:)), name: Notification.Name.didUpdatePreferencesFor, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.onSyncTime(_:)), name: NSNotification.Name.onSyncTime, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.onSyncCallHistory(_:)), name: NSNotification.Name.onSyncCallHistory, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.onDeleteRecord), name: NSNotification.Name.onDeleteRecord, object: nil)
		
//		guard let uuid = UUID(uuidString: CharacteristicUUID.sensing.rawValue) else {
//			return
//		}
//		guard let peripheral = dictionaryDeviceAndPeripheral[uuid]?.peripheral else {
//			return
//		}
//		guard let character = dictionaryDeviceAndPeripheral[uuid]?.interphone.sensingCharacteristic else {
//			return
//		}
//		peripheral.setNotifyValue(false, for: character)
	}
	
	func didEnterBackground() {
//		print(#function)
		centralManager?.stopScan()
//
//		guard let uuid = UUID(uuidString: CharacteristicUUID.sensing.rawValue) else {
//			return
//		}
//		guard let peripheral = dictionaryDeviceAndPeripheral[uuid]?.peripheral else {
//			return
//		}
//		guard let character = dictionaryDeviceAndPeripheral[uuid]?.interphone.sensingCharacteristic else {
//			return
//		}
//		peripheral.setNotifyValue(true, for: character)
	}
	
	func notifyGotVisitor() {
//		print(#function)
		let content = UNMutableNotificationContent()
		content.title = "インターホン通知"
		content.body = "来訪者が訪ねてきています。"
		content.sound = UNNotificationSound.default
		
		let interval = TimeInterval(1)
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
		
		// Create the request
		let uuidString = UUID().uuidString
		let request = UNNotificationRequest(identifier: uuidString,
											content: content, trigger: trigger)
		
		// Schedule the request with the system.
		let notificationCenter = UNUserNotificationCenter.current()
		notificationCenter.add(request) { (error) in
			if error != nil {
				// Handle any errors.
			}
		}
	}
	
	@objc func onRegisterDevice(_ notification: Notification) {
		if let device = notification.object as? InterphoneSensorDevice {
			registerDevice(device)
		}
	}
	
	@objc func onUnregisterDevice(_ notification: Notification) {
		if let device = notification.object as? InterphoneSensorDevice {
			unregisterDevice(device)
		}
	}
	
	@objc func onSyncTime(_ notification: Notification) {
		if let device = notification.object as? InterphoneSensorDevice {

			guard let peripheral = device.peripheral else {
				return
			}

			if device.syncEpochTimeCharacteristic != nil {
				// Must write a lower value of an epoch time value in ordered of lower, upper
				let now = Date()
				let lowerEpochTime = UInt32(now.timeIntervalSince1970)
				peripheral.writeValue(lowerEpochTime.data, for: device.syncEpochTimeCharacteristic!, type: CBCharacteristicWriteType.withResponse)
			}
		}
	}
	
	@objc func onSyncCallHistory(_ notification: Notification) {
		var isReading: Bool = false
		for device in registeredDeviceList {
			if !device.isConnected {
				continue
			}
			guard let peripheral = device.peripheral, let character = device.pingPongRecordCharacteristic else {
				continue
			}
			
			// Must write a lower value of an epoch time value in ordered of lower, upper
			let beginTime: UInt32 = 0
			peripheral.writeValue(beginTime.data, for: character, type: CBCharacteristicWriteType.withResponse)
			peripheral.readValue(for: character)
			isReading = true
		}
		
		if !isReading {
			delegate |> { $0.bleCentral?(didUpdatePingPongListFor: self) }
		}
	}
	
	@objc func onDeleteRecord(_ notification: Notification) {
		guard let time = notification.object as? Date else {
			return
		}
		let timeValue = UInt32(time.timeIntervalSince1970)
		for device in registeredDeviceList {
			if !device.isConnected {
				continue
			}
			guard let peripheral = device.peripheral, let character = device.deleteRecordCharacteristic else {
				continue
			}
			peripheral.writeValue(timeValue.data, for: character, type: CBCharacteristicWriteType.withResponse)
		}
	}
}

