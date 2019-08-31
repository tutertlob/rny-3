//
//  DataExtensions.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/11.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation
import UIKit

extension Data {
	var uint8: UInt8 {
		get {
			var number: UInt8 = 0
			self.copyBytes(to:&number, count: MemoryLayout<UInt8>.size)
			return number
		}
	}
	
	var uint16: UInt16 {
		get {
			let ui16 = self.withUnsafeBytes {
				$0.load(as: UInt16.self)
			}
			return ui16
		}
	}
	
	var uint32: UInt32 {
		get {
			let ui32 = self.withUnsafeBytes {
				$0.load(as: UInt32.self)
			}
			return ui32
		}
	}
	
	var string: String? {
		get {
			let str = self.withUnsafeBytes {
				String(bytes: $0, encoding: String.Encoding.utf8)
			}
			return str
		}
	}
}
