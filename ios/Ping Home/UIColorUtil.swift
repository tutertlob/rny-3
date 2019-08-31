//
//  UIColorUtil.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/02.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import UIKit

class UIColorUtil {
	static func rgb(rgbValue: UInt) -> UIColor {
		return UIColor(red: CGFloat(Float(rgbValue >> 16)/255.0), green: CGFloat(Float((rgbValue >> 8) & 0xff))/255.0, blue: CGFloat(Float(rgbValue & 0xff)/255.0), alpha: CGFloat(1.0))
	}
}
