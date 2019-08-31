//
//  InterphoneSensorDeviceDelegate.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/13.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation

@objc protocol InterphoneSensorDeviceDelegate {
	@objc optional func bleCentral(didUpdatePowerStateFor central: InterphoneSensorDeviceCentral, powerState isPowerOn: Bool)
	@objc optional func bleCentral(didUpdateScanStateFor central: InterphoneSensorDeviceCentral, scanState isScanning: Bool)
	@objc optional func bleCentral(didUpdateDeviceListFor central: InterphoneSensorDeviceCentral)
	@objc optional func bleCentral(didUpdatePingPongListFor central: InterphoneSensorDeviceCentral)
	@objc optional func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didConnect device: InterphoneSensorDevice)
	@objc optional func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didDisconnect device: InterphoneSensorDevice)
	@objc optional func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didUpdateValueFor device: InterphoneSensorDevice)
	@objc optional func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didNotifyInterphoneCall device: InterphoneSensorDevice)
}
