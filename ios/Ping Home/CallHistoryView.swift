//
//  CallHistoryView.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/07/31.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit

class CallHistoryView: UITableViewController, InterphoneSensorDeviceDelegate {
	
	@IBOutlet var callHistoryView: UITableView!
	private var pingPongHistories: [CallHistory] = []
	
//	enum Keys: String {
//		case pingPongHistories
//	}
	let sections: [SectionElement] = [SectionElement(headerTitle: "インターホン履歴")]
	
	override func numberOfSections(in tableView: UITableView) -> Int {
//		print(#function)
		return sections.count
	}
	
	override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
		return 55
	}
	
	override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		let frame = CGRect(x: 16.0, y: 0.0, width: 160, height: 55)
		let view = UIView(frame: CGRect.zero)
		let label = UILabel(frame: frame)
		let font = UIFont.systemFont(ofSize: 20)
		label.font = font
		label.text = sections[0].headerTitle
		view.addSubview(label)
		return view
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		print(#function)
		if pingPongHistories.isEmpty {
			return 1
		} else {
			return pingPongHistories.count
		}
	}
	
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 60.0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Call", for: indexPath)
		
		if pingPongHistories.isEmpty {
			cell.textLabel?.text = "履歴なし"
			cell.detailTextLabel?.text = ""
		} else {
			cell.textLabel?.text = pingPongHistories[indexPath.row].text
			cell.detailTextLabel?.text = pingPongHistories[indexPath.row].timeOfCall
		}
		return cell
	}
	
	override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//		print(#function)
		let record = pingPongHistories.remove(at: indexPath.row)
		CallHistoryManager.sharedInstace.remove(timestamp: record.date)
		if (pingPongHistories.isEmpty) {
			tableView.reloadData()
		} else {
			tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
		}
		NotificationCenter.default.post(name: NSNotification.Name.onDeleteRecord, object: record.date)
	}
	
	@objc func syncCallHistory() {
		NotificationCenter.default.post(name: NSNotification.Name.onSyncCallHistory, object: nil)
	}

	func bleCentral(didUpdatePingPongListFor central: InterphoneSensorDeviceCentral) {
		callHistoryView.refreshControl?.endRefreshing()
		pingPongHistories = CallHistoryManager.sharedInstace.callHistories
		tableView.reloadData()
	}
	
	func interphoneSensorDevice(_ central: InterphoneSensorDeviceCentral, didNotifyInterphoneCall device: InterphoneSensorDevice) {
		pingPongHistories.insert(CallHistory(), at: 0)
		if pingPongHistories.count > 20 {
			pingPongHistories.removeLast()
		}
		tableView.reloadData()
	}
	
//	func loadPingPongHistories() {
//		guard let json = UserDefaults.standard.object(forKey: Keys.pingPongHistories.rawValue) as? String else {
//			return
//		}
//		guard let jsonData = json.data(using: String.Encoding.utf8) else {
//			return
//		}
//		pingPongHistories.removeAll()
//		let jsonDecoder = JSONDecoder()
//		pingPongHistories = try! jsonDecoder.decode([CallHistory].self, from: jsonData)
//	}
	
//	func storePingPongHistories() {
//		let jsonEncoder = JSONEncoder()
//		let jsonData = try! jsonEncoder.encode(pingPongHistories)
//		let json = String(bytes: jsonData, encoding: String.Encoding.utf8)!
//		UserDefaults.standard.set(json, forKey: Keys.pingPongHistories.rawValue)
//		UserDefaults.standard.synchronize()
//	}

//	@objc func onWillTerminate(_ notification: Notification?) {
//		storePingPongHistories()
//	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
//		NotificationCenter.default.addObserver(self, selector: #selector(CallHistoryView.onWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
//		loadPingPongHistories()
		InterphoneSensorDeviceCentral.sharedInstance.delegate += self
		callHistoryView.refreshControl = UIRefreshControl()
		callHistoryView.refreshControl!.addTarget(self, action: #selector(CallHistoryView.syncCallHistory), for: UIControl.Event.valueChanged)
		pingPongHistories = CallHistoryManager.sharedInstace.callHistories
	}
	
}
