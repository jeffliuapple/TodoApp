//
//  File.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation
import FirebaseFirestore

class TodoService {
  
  // MARK: - Properties
  
  private let endpoint = FirebaseEndpoint.todos
  
  // MARK: - CRUD
  
  func fetchTodos(completion: @escaping (Result<[Todo], NetworkError>) -> Void ) {
    endpoint.collectionRef.order(by: "createdAt", descending: true)
      .getDocuments { snapshot, error in
        
        if let error {
          completion(.failure(.firestoreError(error)))
          return
        }
        
        guard let documents = snapshot?.documents else {
          completion(.failure(.invalidData))
          return
        }
        
        let todos = documents.compactMap { Todo.fromDocument($0) }
        completion(.success(todos))
      }
  }
    
  func fetchTodo(id: String, completion: @escaping (Result<Todo, NetworkError>) -> Void ) {
    guard let docRef = FirebaseEndpoint.todo(id: id).documentRef else {
      completion(.failure(.invalidData))
      return
    }
  
    docRef.getDocument {snapshot, error in
      if let error {
        completion(.failure(.firestoreError(error)))
        return
      }
  
      guard let snapshot = snapshot, snapshot.exists else {
        completion(.failure(.documentNotFound))
        return
      }
  
      guard let todo = Todo.fromDocument(snapshot) else {
        completion(.failure(.decodingFailed))
        return
      }
  
      completion(.success(todo))
    }
  }
  
  func createTodo(_ todo: Todo, completion: @escaping (Result<Todo, NetworkError>) -> Void) {
    var newTodo = todo
    let data = newTodo.toDictionary()
    
    let docRef = endpoint.collectionRef.addDocument(data: data) { error in
      if let error {
        completion(.failure(.firestoreError(error)))
        return
      }
    }
    
    newTodo.id = docRef.documentID
    completion(.success(newTodo))
  }
  
  func updateTodo(_ todo: Todo, completion: @escaping (Result<Todo, NetworkError>) -> Void ) {
    guard let id = todo.id else {
      completion(.failure(.invalidData))
      return
    }
    
    guard let docRef = FirebaseEndpoint.todo(id: id).documentRef else {
      completion(.failure(.invalidData))
      return
    }
    
    var updatedTodo = todo
    updatedTodo.updatedAt = Date()
    
    let data = updatedTodo.toDictionary()
    
    docRef.updateData(data) { error in
      if let error {
        completion(.failure(.firestoreError(error)))
        return
      }
      completion(.success(updatedTodo))
    }
  }
  
  func toggleTodo(id: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
    guard let docRef = FirebaseEndpoint.todo(id: id).documentRef else {
      completion(.failure(.invalidData))
      return
    }
    
    docRef.getDocument { snapshot, error in
      if let error = error {
        completion(.failure(.firestoreError(error)))
        return
      }
      
      guard let snapshot = snapshot,
            let todo = Todo.fromDocument(snapshot) else {
        completion(.failure(.documentNotFound))
        return
      }
      
      let newStatus = !todo.completed
      
      docRef.updateData([
        "completed": newStatus,
        "updatedAt": Timestamp(date: Date())
      ]) { error in
        if let error = error {
          completion(.failure(.firestoreError(error)))
          return
        }
        
        completion(.success(()))
      }
    }
  }

  func deleteTodo(id: String, completion: @escaping (Result<Void, NetworkError>) -> Void ) {
    guard let docRef = FirebaseEndpoint.todo(id: id).documentRef else {
      completion(.failure(.invalidData))
      return
    }
    
    docRef.delete { error in
      if let error {
        completion(.failure(.firestoreError(error)))
        return
      }
      
      completion(.success(()))
    }
  }
  
}
