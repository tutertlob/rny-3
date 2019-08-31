//
//  NumberExtensions.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/15.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

extension UInt16 {
	var data: Data {
		get {
			return withUnsafeBytes(of: self) { Data($0) }
		}
	}
}

extension UInt32 {
	var data: Data {
		get {
			return withUnsafeBytes(of: self, { Data($0) })
		}
	}
}
