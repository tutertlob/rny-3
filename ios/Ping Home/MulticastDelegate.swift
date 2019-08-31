//
//  MulticastDelegate.swift
//  Ping Home
//
//  Created by 西山 零士 on 2019/08/17.
//  Copyright © 2019 西山 零士. All rights reserved.
//

import Foundation

open class MulticastDelegate<T> {
	
	private let delegates: NSHashTable<AnyObject>
	
	public var isEmpty: Bool {
		
		return delegates.allObjects.count == 0
	}
	
	public init(strongReferences: Bool = false) {
		
		delegates = strongReferences ? NSHashTable<AnyObject>() : NSHashTable<AnyObject>.weakObjects()
	}
	
	public init(options: NSPointerFunctions.Options) {
		
		delegates = NSHashTable<AnyObject>(options: options, capacity: 0)
	}
	
	public func addDelegate(_ delegate: T) {
		
		delegates.add(delegate as AnyObject)
	}
	
	public func removeDelegate(_ delegate: T) {
		
		delegates.remove(delegate as AnyObject)
	}
	
	public func invokeDelegates(_ invocation: (T) -> ()) {
		
		for delegate in delegates.allObjects {
			invocation(delegate as! T)
		}
	}
	
	public func containsDelegate(_ delegate: T) -> Bool {
		
		return delegates.contains(delegate as AnyObject)
	}
}

public func +=<T>(left: MulticastDelegate<T>, right: T) {
	
	left.addDelegate(right)
}

public func -=<T>(left: MulticastDelegate<T>, right: T) {
	
	left.removeDelegate(right)
}

precedencegroup MulticastPrecedence {
	associativity: left
	higherThan: TernaryPrecedence
}
infix operator |> : MulticastPrecedence
public func |><T>(left: MulticastDelegate<T>, right: (T) -> ()) {
	
	left.invokeDelegates(right)
}
