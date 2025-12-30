//
//  PrintManager.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation

struct PrintManager {
  
  private init() {}
  
  static func printTodoVC(_ info: String) {
    print("ToodVC: \(info)")
  }
  
  static var isPrintLocalStorage: Bool = true
  static func printLocalStorage(_ items: Any...,
                                file: String = #file,
                                function: String = #function,
                                line: Int = #line,
                                separator: String = " ",
                                terminator: String = "\n") {
    if isPrintLocalStorage {
      let fileName = (file as NSString).lastPathComponent
      print("[\(fileName):\(line)] \(function) -", items, separator: separator, terminator: terminator)
    }
  }
  
  static var isPrintTodoListVM: Bool = true
  static func printTodoListVM(_ items: Any...,
                              file: String = #file,
                              function: String = #function,
                              line: Int = #line,
                              separator: String = " ",
                              terminator: String = "\n") {
    if isPrintTodoListVM {
      let fileName = (file as NSString).lastPathComponent
      print("[\(fileName):\(line)] \(function) -", items, separator: separator, terminator: terminator)
    }
  }
  
}
