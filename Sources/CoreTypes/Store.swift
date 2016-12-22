//
//  Store.swift
//  ReactiveReSwift
//
//  Created by Charlotte Tortorella on 11/17/16.
//  Copyright © 2016 Benjamin Encz. All rights reserved.
//

import Foundation

/**
 This class is the default implementation of the `Store` protocol. You will use this
 store in most of your applications. You shouldn't need to implement your own store.
 You initialize the store with a reducer and an initial application state,
 contained within an observable.
 */

import Foundation

public class Store<ObservableProperty: ObservablePropertyType>: StoreType where ObservableProperty.ValueType: StateType {

    public typealias StoreMiddleware = Middleware<ObservableProperty.ValueType>
    public typealias StoreReducer = Reducer<ObservableProperty.ValueType>

    public var dispatchMiddleware: Middleware<ObservableProperty.ValueType>!

    private var reducer: StoreReducer

    public var observable: ObservableProperty!

    private let dispatchingLock = NSLock()

    private var disposeBag = SubscriptionReferenceBag()

    public required convenience init(reducer: StoreReducer, stateType: ObservableProperty.ValueType.Type, observable: ObservableProperty) {
        self.init(reducer: reducer, stateType: stateType, observable: observable, middleware: Middleware())
    }

    public required init(reducer: StoreReducer, stateType: ObservableProperty.ValueType.Type, observable: ObservableProperty, middleware: StoreMiddleware) {
        self.reducer = reducer
        self.observable = observable
        self.dispatchMiddleware = middleware
    }

    private func defaultDispatch(action: Action) {
        guard dispatchingLock.try() else {
            raiseFatalError("ReSwift:IllegalDispatchFromReducer - Reducers may not dispatch actions.")
        }
        observable.value = reducer.transform(action, observable.value)
        dispatchingLock.unlock()
    }

    public func dispatch(_ actions: Action...) {
        actions.flatMap { action in
            dispatchMiddleware.transform({ self.observable.value }, { self.dispatch($0) }, action)
        }.forEach(defaultDispatch)
    }

    public func dispatch<S: StreamType>(_ stream: S) where S.ValueType: Action {
        disposeBag += stream.subscribe { [unowned self] action in
            self.dispatch(action)
        }
    }
}