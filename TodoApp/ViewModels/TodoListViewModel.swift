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
    setLoading(true)
    
    todoService.fetchTodos { [weak self] result in
      guard let self else { return }
      setLoading(false)

      DispatchQueue.main.async {
        switch result {
        case .success(let todos):
          self.todos = todos
          self.notifyTodosUpdated()
          self.notifyEmptyStateChanged()
        case .failure(let error):
          self.onError?(error.localizedDescription)
        }
      }
    }
  }
  
  func createTodo(title: String) {
    let newTodo = Todo.create(title: title)
    
    todoService.createTodo(newTodo) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let todo):
          self?.todos.insert(todo, at: 0)
          self?.notifyTodosUpdated()
          self?.notifyEmptyStateChanged()
        case .failure(let error):
          self?.onError?(error.localizedDescription)
        }
      }
    }
  }
  
  func toggleTodo(at indexPath: IndexPath) {
    guard indexPath.row < todos.count,
          let id = todos[indexPath.row].id else { return }
    todoService.toggleTodo(id: id) { [weak self] result in
      guard let self else { return }
      
      DispatchQueue.main.async {
        switch result {
        case .success():
          self.todos[indexPath.row].completed.toggle()
          self.notifyTodosUpdated()
        case .failure(let error):
          self.onError?(error.localizedDescription)
        }
      }
    }
  }
  
  func deleteTodo(at indexPath: IndexPath) {
    guard indexPath.row < todos.count,
          let id = todos[indexPath.row].id else { return }
    
    todoService.deleteTodo(id: id) { result in
      DispatchQueue.main.async {
        switch result {
        case .success():
          self.todos.remove(at: indexPath.row)
          self.notifyTodosUpdated()
          self.notifyEmptyStateChanged()
        case .failure(let error):
          self.onError?(error.localizedDescription)
        }
      }
    }
  }
  
  // MARK: - Private Methods
  
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
