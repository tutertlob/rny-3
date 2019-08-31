//
//  TableViewController.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/07/31.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit
import CoreBluetooth

class DeviceListViewController: UITableViewController, CBPeripheralDelegate, InterphoneSensorDeviceDelegate {
	@IBOutlet weak var registeredDeviceView: UITableView!
	
	private var selectedInterphoneSensorDevice: InterphoneSensorDevice?
	
	private let indicator = UIActivityIndicatorView()
	
	enum SectionFor: Int {
		case registeredDevice = 0
		case unregisteredDevice = 1
	}
	
	private let sections: [SectionElement] = [
		SectionElement(headerTitle: "登録済みセンサー"),
		SectionElement(headerTitle: "見つかったセンサー")
	]
	
	private var registeredDeviceList: [InterphoneSensorDevice] = []
	private var unregisteredDeviceList: [InterphoneSensorDevice] = []

	override func numberOfSections(in tableView: UITableView) -> Int {
		return sections.count
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		if section == SectionFor.registeredDevice.rawValue {
			return registeredDeviceList.count
		} else {
			return unregisteredDeviceList.count
		}
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = UITableViewCell(style: UITableViewCell.CellStyle.value1, reuseIdentifier: "Devices")

		//
		// section:
		// 0 for registered sensors
		// 1 for unregistered sensors
		//
		if indexPath.section == SectionFor.registeredDevice.rawValue {
			cell.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
			let device = registeredDeviceList[indexPath.row]
			cell.textLabel!.text = device.nickname ?? ""
			cell.detailTextLabel!.text = device.mac
			if device.isConnected {
				cell.textLabel?.textColor = .black
			} else {
				cell.textLabel?.textColor = .gray
			}
		} else {
			let item = unregisteredDeviceList[indexPath.row]
			cell.textLabel!.text = item.nickname
			cell.detailTextLabel!.text = ""
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		if indexPath.section == SectionFor.registeredDevice.rawValue {
			tableView.deselectRow(at: indexPath, animated: true)
			selectedInterphoneSensorDevice = registeredDeviceList[indexPath.row]
			performSegue(withIdentifier: "toDevicePropertyView", sender: nil)
		} else {
			tableView.deselectRow(at: indexPath, animated: true)
			let device = unregisteredDeviceList[indexPath.row]
			NotificationCenter.default.post(name: Notification.Name.onRegisterDevice, object: device)
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		switch section {
		case SectionFor.registeredDevice.rawValue:
			return 38.0
		case SectionFor.unregisteredDevice.rawValue:
			return 38.0
		default:
			return tableView.sectionHeaderHeight
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
		return 0.0
	}

	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		if let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "SectionHeaderFootter") {
			header.textLabel!.text = sections[section].headerTitle
			
			if section == SectionFor.unregisteredDevice.rawValue {
				let rect = tableView.rectForHeader(inSection: section)
				indicator.color = .gray
				indicator.frame = CGRect(x: (rect.width - 20.0) / 2.0, y: (rect.height - 20.0) * 0.75, width: 20.0, height: 20.0)
				if InterphoneSensorDeviceCentral.sharedInstance.isScanning {
					indicator.startAnimating()
				}
				header.addSubview(indicator)
			}
			
			return header
		}

		return nil
	}
	
	override func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
		switch section {
		case SectionFor.registeredDevice.rawValue:
			return 38.0
		case SectionFor.unregisteredDevice.rawValue:
			return 38.0
		default:
			return tableView.sectionHeaderHeight
		}
	}
	
	func bleCentral(didUpdateScanStateFor central: InterphoneSensorDeviceCentral, scanState isScanning: Bool) {
		if isScanning {
			indicator.startAnimating()
		} else {
			indicator.stopAnimating()
		}
	}
	
	func bleCentral(didUpdatePowerStateFor central: InterphoneSensorDeviceCentral, powerState isPowerOn: Bool) {
		tableView.reloadData()
	}
	
	func bleCentral(didUpdateDeviceListFor central: InterphoneSensorDeviceCentral) {
		registeredDeviceList = central.registeredDeviceList
		unregisteredDeviceList = central.unregisteredDeviceList
		registeredDeviceView.reloadData()
	}
	
	func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didConnect device: InterphoneSensorDevice) {
		if let index = registeredDeviceList.firstIndex(where: { $0.peripheralId == device.peripheralId }) {
			let cell = registeredDeviceView.cellForRow(at: IndexPath(row: index, section: SectionFor.registeredDevice.rawValue))
			cell?.textLabel?.textColor = .black
			cell?.accessoryType = UITableViewCell.AccessoryType.disclosureIndicator
		}
	}
	
	func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didDisconnect device: InterphoneSensorDevice) {
		if let index = registeredDeviceList.firstIndex(where: { $0.peripheralId == device.peripheralId }) {
			let cell = registeredDeviceView.cellForRow(at: IndexPath(row: index, section: SectionFor.registeredDevice.rawValue))
			cell?.textLabel?.textColor = .gray
		}
	}
	
	@objc func didUpdatePreferencesFor(_ notificatio: Notification) {
		tableView.reloadData()
	}
	
	//
	// For hadling view controller
	//
	override func viewWillAppear(_ animated: Bool) {

	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "toDevicePropertyView" {
			let viewController = segue.destination as! DevicePropertyView
			viewController.subjectSensor = selectedInterphoneSensorDevice
			segue.destination.hidesBottomBarWhenPushed = true
			viewController.delegate = self
		}
	}
	
	func applicationDidEnterBackgroun(_ application: UIApplication) {
//		print("suspended")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
		NotificationCenter.default.addObserver(self, selector: #selector(InterphoneSensorDeviceCentral.didUpdatePreferencesFor(_:)), name: Notification.Name.didUpdatePreferencesFor, object: nil)
		
		registeredDeviceView.register(UITableViewHeaderFooterView.self, forHeaderFooterViewReuseIdentifier: "SectionHeaderFootter")
		let central = InterphoneSensorDeviceCentral.sharedInstance
		registeredDeviceList = central.registeredDeviceList
		unregisteredDeviceList = central.unregisteredDeviceList

		central.delegate += self
	}
}
