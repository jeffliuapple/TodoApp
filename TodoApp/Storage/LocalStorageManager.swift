//
//  LocalStorageManager.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/24.
//

import Foundation

class LocalStorageManager {
  static let shared = LocalStorageManager()
  
  private init() {}
  
  // MARK: - Properties
  
  private let userDefaults = UserDefaults.standard
  private let todosKey = "saved_todos"
  
  // MARK: - Public Methods
  
  func saveTodos(_ todos: [Todo]) {
    do {
      let encoder = JSONEncoder()
      let data = try encoder.encode(todos)
      userDefaults.set(data, forKey: todosKey)
      
      PrintManager.printLocalStorage("success, count = \(todos.count)")
    } catch {
      PrintManager.printLocalStorage("error: \(error.localizedDescription)")
    }
  }
  
  func loadTodos() -> [Todo] {
    guard let data = userDefaults.data(forKey: todosKey) else {
      PrintManager.printLocalStorage("count = 0")
      return []
    }
    
    do {
      let decoder = JSONDecoder()
      let todoss = try decoder.decode([Todo].self, from: data)
      PrintManager.printLocalStorage("count: \(todoss.count)")
      return todoss
    } catch {
      PrintManager.printLocalStorage("error: \(error.localizedDescription)")
      return []
    }
  }
  
  func clearTodos() {
    userDefaults.removeObject(forKey: todosKey)
    PrintManager.printLocalStorage("clearTodos.")
  }
  
  func hasCachedData() -> Bool {
    return userDefaults.data(forKey: todosKey) != nil
  }
}

