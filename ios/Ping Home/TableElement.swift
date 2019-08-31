//
//  TableElements.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/02.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit

struct CellElement {
	let content: String
	let detail: String?
	let accessoryType: UITableViewCell.AccessoryType
	let needSwitch: Bool
	let switchIsOn: Bool

	init(content: String, detail: String? = nil, accessoryType: UITableViewCell.AccessoryType = UITableViewCell.AccessoryType.none, needSwitch: Bool = false, switchIsOn: Bool = false) {
		self.content = content
		self.detail = detail
		self.accessoryType = accessoryType
		self.needSwitch = needSwitch
		self.switchIsOn = switchIsOn
	}
}

struct SectionElement {
	let headerTitle: String?
	let footerTitle: String?
	var cells: [CellElement]?
	
	init(headerTitle: String? = nil, footerTitle: String? = nil, cells: [CellElement]? = nil) {
		self.headerTitle = headerTitle
		self.footerTitle = footerTitle
		self.cells = cells
	}
}
