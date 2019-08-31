//
//  NotificationExtension.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/17.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit

extension Notification.Name {
	static let onRegisterDevice = Notification.Name(rawValue: "onRegisterDevice")
	static let onUnregisterDevice = Notification.Name(rawValue: "onUnregisterDevice")
	static let onSyncTime = Notification.Name(rawValue: "onSyncTime")
	static let onSyncCallHistory = Notification.Name(rawValue: "onSyncCallHistory")
	static let onDeleteRecord = Notification.Name(rawValue: "onDeleteRecord")
	
//	static let didUpdatePowerStateFor = Notification.Name(rawValue: "didUpdatePowerStateFor")
//	static let didUpdateScanStateFor = Notification.Name(rawValue: "didUpdateScanStateFor")
//	static let didUpdateDeviceListFor = Notification.Name(rawValue: "didUpdateDeviceListFor")
//	static let didConnect = Notification.Name(rawValue: "didConnect")
//	static let didDisconnect = Notification.Name(rawValue: "didDisconnect")
//	static let didUpdateValueFor = Notification.Name(rawValue: "didUpdateValueFor")
//	static let didNotifyInterphoneCall = Notification.Name(rawValue: "didNotifyInterphoneCall")
	
	static let didUpdatePreferencesFor = Notification.Name(rawValue: "didUpdatePreferencesFor")

}
