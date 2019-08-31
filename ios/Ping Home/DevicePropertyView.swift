//
//  DevicePropertyView.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/07/31.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit

class DevicePropertyView: UITableViewController, UITextFieldDelegate, InterphoneSensorDeviceDelegate {
	@IBOutlet weak var connectSwitch: UISwitch!
	@IBOutlet weak var modelNameLabel: UILabel!
	@IBOutlet weak var bdAddressLabel: UILabel!
	@IBOutlet var devicePropertyTable: UITableView!
	@IBOutlet weak var nicknameField: UITextField!
	@IBOutlet weak var thresholdField: UITextField!
	
	enum Section: Int, CaseIterable {
		case connecting = 0
		case nicknameAndThreshold = 1
		case deviceProfile = 2
		case unregisterDevice = 3
		case syncTime = 4
	}
	
	var delegate: DeviceListViewController?
	var subjectSensor: InterphoneSensorDevice?
	
	@IBAction func onToggle(_ sender: UISwitch) {
//		print("onToggle")
		subjectSensor?.enableConnect = sender.isOn
		NotificationCenter.default.post(name: NSNotification.Name.didUpdatePreferencesFor, object: subjectSensor)
		if !connectSwitch.isOn {
			tableView.reloadData()
		}
	}
	
	override func numberOfSections(in tableView: UITableView) -> Int {
//		print("DevicePropertyView: numberOfSection")
		return Section.allCases.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		switch section {
		case Section.connecting.rawValue:
			return 1
		case Section.nicknameAndThreshold.rawValue:
			if subjectSensor!.isConnected {
				return 2
			} else {
				return 0
			}
		case Section.deviceProfile.rawValue:
			if subjectSensor!.isConnected {
				return 2
			} else {
				return 0
			}
		case Section.unregisterDevice.rawValue:
			return 1
		case Section.syncTime.rawValue:
			if subjectSensor!.isConnected {
				return 1
			} else {
				return 0
			}
		default:
			return 0
		}
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		switch section {
		case Section.connecting.rawValue:
			return nil
		case Section.nicknameAndThreshold.rawValue:
			if subjectSensor!.isConnected {
				return "ニックネーム・閾値"
			} else {
				return nil
			}
		case Section.deviceProfile.rawValue:
			if subjectSensor!.isConnected {
				return "センサー情報"
			} else {
				return nil
			}
		case Section.unregisterDevice.rawValue:
			return nil
		default:
			return nil
		}
	}
	
//	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//		let section = Section(rawValue: indexPath.section)
//		if section == Section.connecting {
//			return UITableView.automaticDimension
//		} else {
//			if connectSwitch.isOn {
//				return UITableView.automaticDimension
//			} else {
//				return 0.0
//			}
//		}
//	}

	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
		switch indexPath.section {
		case Section.connecting.rawValue:
			let isOn = subjectSensor?.enableConnect ?? false
			connectSwitch.isOn = isOn
			
		case Section.nicknameAndThreshold.rawValue:
			if indexPath.row == 0 {
				nicknameField.text = subjectSensor!.nickname ?? subjectSensor!.modelName
			} else {
				thresholdField.text = String(format: "%d", subjectSensor!.threshold)
			}
			
		case Section.deviceProfile.rawValue:
			if indexPath.row == 0 {
				modelNameLabel.text = subjectSensor?.modelName
			} else {
				bdAddressLabel.text = subjectSensor?.mac
			}
		default:
			break
		}
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == Section.unregisterDevice.rawValue {
//			print("DevicePropertyView: select")
			tableView.deselectRow(at: indexPath, animated: true)
			NotificationCenter.default.post(name: Notification.Name.onUnregisterDevice, object: subjectSensor)
			self.navigationController?.popViewController(animated: true)
			subjectSensor = nil
		} else if indexPath.section == Section.syncTime.rawValue {
			tableView.deselectRow(at: indexPath, animated: true)
			NotificationCenter.default.post(name: NSNotification.Name.onSyncTime, object: subjectSensor)
		}
	}
	
	override func scrollViewDidScroll(_ scrollView: UIScrollView) {
		return
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField.tag == 0 {
			return nicknameField.resignFirstResponder()
		} else {
			return thresholdField.resignFirstResponder()
		}
	}
	
	func textFieldDidEndEditing(_ textField: UITextField) {
		if textField.tag == 0 {
			subjectSensor?.nickname = textField.text
		} else {
			if let threshold = UInt16(textField.text!) {
				subjectSensor?.threshold = threshold
			}
		}
		NotificationCenter.default.post(name: NSNotification.Name.didUpdatePreferencesFor, object: subjectSensor)
	}
	
	func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didDisconnect device: InterphoneSensorDevice) {
		tableView.reloadData()
	}
	
	func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didUpdateValueFor device: InterphoneSensorDevice) {
		tableView.reloadData()
	}
	
	func bleCentral(didUpdatePowerStateFor central: InterphoneSensorDeviceCentral, powerState isPowerOn: Bool) {
		if !isPowerOn {
			tableView.reloadData()
		}
	}
	
	@objc func doneEdittingNicknameAndThreshold() {
		self.view.endEditing(true)
	}
	
	func addToolbarForTextField() {
		let toolBar = UIToolbar()
		toolBar.barStyle = UIBarStyle.default
		toolBar.isTranslucent = true
		toolBar.barTintColor = UIColor.white
		
		let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.done, target: self, action: #selector(DevicePropertyView.doneEdittingNicknameAndThreshold))
		let flexibleSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil)
		toolBar.setItems([flexibleSpace, doneButton], animated: false)
		toolBar.isUserInteractionEnabled = true
		toolBar.sizeToFit()
		nicknameField.delegate = self
		nicknameField.inputAccessoryView = toolBar
		thresholdField.delegate = self
		thresholdField.inputAccessoryView = toolBar
	}
	
	override func viewWillAppear(_ animated: Bool) {
		InterphoneSensorDeviceCentral.sharedInstance.delegate += self
		tableView.reloadData()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		InterphoneSensorDeviceCentral.sharedInstance.delegate -= self
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		addToolbarForTextField()
	}
}
