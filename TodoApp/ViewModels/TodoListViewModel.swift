//
//  TodoListViewModel.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/24.
//

import Foundation
import UIKit

class TodoListViewModel {
  
  // MARK: - Properties
  
  private(set) var todos: [Todo] = []
  private let todoService = TodoService()
  
  private let storageManager = LocalStorageManager.shared
  
  private(set) var isLoading: Bool = false
  
  // MARK: - Binding
  
  var onLoadingStateChanged: ((Bool) -> Void)?
  
  var onTodosUpdated: (([Todo]) -> Void)?
  
  var onEmptyStateChanged: ((Bool) -> Void)?
  
  var onError: ((String) -> Void)?
  
  // MARK: - Computed Properties
  
  var todosCount: Int { todos.count }
  
  var isEmpty: Bool { todos.isEmpty }
  
  var heightForRow: CGFloat { 50.0 }
  
  // MARK: - Public Methods
  
  func todo(at index: Int) -> Todo? {
    guard index >= 0 && index < todos.count else {
      return nil
    }
    return todos[index]
  }
  
  func loadTodos() {
    // Local data
    loadFromLocal()
    
    // Download cloud + Upload local data
    syncFromCloud()
  }
  
  func createTodo(title: String) {
    var newTodo = Todo.createWithTempId(title: title)
    newTodo.isUploading = true
    
    todos.insert(newTodo, at: 0)
    saveToLocal()
    notifyTodosUpdated()
    notifyEmptyStateChanged()
    
    todoService.createTodo(newTodo) { [weak self] result in
      guard let self else { return }
      
      DispatchQueue.main.async {
        switch result {
        case .success(var serverTodo):
          if let index = self.todos.firstIndex(where: {
            $0.clientId == serverTodo.clientId
          }) {

            let local = self.todos[index]
            let localCompleted = local.completed
            let cloudCompleted = serverTodo.completed
            
            serverTodo.completed = localCompleted
            serverTodo.updatedAt = max(local.updatedAt, serverTodo.updatedAt)
            serverTodo.isUploading = false
            
            self.todos[index] = serverTodo
            self.saveToLocal()
            self.notifyTodosUpdated()

            if let id = serverTodo.id, localCompleted != cloudCompleted {
              self.todoService.setTodoCompleted(id: id, completed: localCompleted) { _ in }
            }

            PrintManager.printTodoListVM("created: \(serverTodo.title)")
          }
          
        case .failure(let error):
          PrintManager.printTodoListVM("create failed, will sync later: \(error.localizedDescription)")
          
          if let index = self.todos.firstIndex(where: {
            $0.hasTempId && $0.clientId == newTodo.clientId
          }) {
            self.todos[index].isUploading = false
            self.saveToLocal()
          }
        }
      }
    }
  }
  
  func toggleTodo(at indexPath: IndexPath) {
    guard indexPath.row < todos.count else { return }

    todos[indexPath.row].completed.toggle()
    todos[indexPath.row].updatedAt = Date()
    saveToLocal()
    notifyTodosUpdated()

    if todos[indexPath.row].hasTempId {
      PrintManager.printTodoListVM("toggled local item (pending upload)")
      return
    }

    guard let id = todos[indexPath.row].id else { return }
    let completed = todos[indexPath.row].completed

    todoService.setTodoCompleted(id: id, completed: completed) { result in
      switch result {
      case .success:
        PrintManager.printTodoListVM("synced completed=\(completed) to cloud")
      case .failure(let error):
        PrintManager.printTodoListVM("sync failed (kept local): \(error.localizedDescription)")
      }
    }
  }
  
  func deleteTodo(at indexPath: IndexPath) {
    guard indexPath.row < todos.count else { return }
    
    let deletedTodo = todos[indexPath.row]
    todos.remove(at: indexPath.row)
    saveToLocal()
    notifyTodosUpdated()
    notifyEmptyStateChanged()
    
    if deletedTodo.hasTempId {
      PrintManager.printTodoListVM("deleted local item")
      return
    }
    
    guard let id = deletedTodo.id else { return }
    
    todoService.deleteTodo(id: id) { result in
      switch result {
      case .success():
        PrintManager.printTodoListVM("deleted from cloud")
        
      case .failure(let error):
        PrintManager.printTodoListVM("delete failed (kept local): \(error.localizedDescription)")
      }
    }
  }
  
  // MARK: - Private Methods
  
  private func saveToLocal() {
    storageManager.saveTodos(todos)
  }
  
  private func loadFromLocal() {
    let cachedTodos = storageManager.loadTodos()
    
    if !cachedTodos.isEmpty {
      todos = cachedTodos
      notifyTodosUpdated()
      notifyEmptyStateChanged()
    }
  }
  
  private func syncFromCloud() {
    self.setLoading(true)
    
    todoService.fetchTodos { [weak self] result in
      guard let self else { return }

      DispatchQueue.main.async {
        self.setLoading(false)
        
        switch result {
        case .success(let cloudTodos):
          PrintManager.printTodoListVM("cloudTodos count = \(cloudTodos.count)")

          self.mergeTodosAndSyncLocal(cloudTodos: cloudTodos)
          
        case .failure(let error):
          PrintManager.printTodoListVM("fetch failed")

          self.syncLocalTodosToCloud()
          
          if self.todos.isEmpty {
            self.onError?(error.localizedDescription)
          }
        }
      }
    }
  }
  
  private func mergeTodosAndSyncLocal(cloudTodos: [Todo]) {
    let localOnly = todos.filter { $0.hasTempId }
    let combined = cloudTodos + localOnly
        
    let deduped = Dictionary(grouping: combined, by: { $0.clientId })
      .compactMap { (_, items) in
        items.max(by: { $0.updatedAt < $1.updatedAt })
      }
    
    todos = deduped.sorted { $0.createdAt > $1.createdAt }
    
    PrintManager.printTodoListVM("merged: \(todos.count) items")
    if !localOnly.isEmpty {
      PrintManager.printTodoListVM("kept \(localOnly.count) local items")
    }
    
    saveToLocal()
    notifyTodosUpdated()
    notifyEmptyStateChanged()
    
    syncLocalTodosToCloud()
  }
  
  private func syncLocalTodosToCloud() {
    uploadLocalOnlyTodos()
  }
  
  private func uploadLocalOnlyTodos() {
    let localOnlyTodos = todos.filter { $0.hasTempId && !$0.isUploading }
    
    guard !localOnlyTodos.isEmpty else { return }
    
    PrintManager.printTodoListVM("uploading \(localOnlyTodos.count) local items...")
    
    for localTodo in localOnlyTodos {
      if let i = self.todos.firstIndex(where: { $0.clientId == localTodo.clientId }) {
        self.todos[i].isUploading = true
        self.saveToLocal()
      }
      
      todoService.createTodo(localTodo) { [weak self] result in
        guard let self else { return }
        
        DispatchQueue.main.async {
          switch result {
          case .success(var cloudTodo):
            if let index = self.todos.firstIndex(where: { $0.hasTempId && $0.clientId == cloudTodo.clientId }) {

              let local = self.todos[index]
              let localCompleted = local.completed
              let cloudCompleted = cloudTodo.completed
              
              cloudTodo.completed = localCompleted
              cloudTodo.updatedAt = max(local.updatedAt, cloudTodo.updatedAt)
              cloudTodo.isUploading = false
              
              self.todos[index] = cloudTodo
              self.saveToLocal()
              self.notifyTodosUpdated()

              if let id = cloudTodo.id, cloudCompleted != localCompleted {
                self.todoService.setTodoCompleted(id: id, completed: localCompleted) { _ in }
              }
            }
            
          case .failure(let error):
            PrintManager.printTodoListVM("upload failed: \(localTodo.title) - \(error.localizedDescription)")
            
            if let index = self.todos.firstIndex(where: {
              $0.clientId == localTodo.clientId
            }) {
              self.todos[index].isUploading = false
              self.saveToLocal()
            }
          }
        }
      }
    }
  }


  private func setLoading(_ loading: Bool) {
    isLoading = loading
    onLoadingStateChanged?(loading)
  }
  
  private func notifyTodosUpdated() {
    onTodosUpdated?(todos)
  }
  
  private func notifyEmptyStateChanged() {
    onEmptyStateChanged?(isEmpty)
  }
  
}
