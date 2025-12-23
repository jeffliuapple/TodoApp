//
//  Untitled.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation
import FirebaseFirestore

enum FirebaseEndpoint {
  case todos
  case todo(id: String)
  
  // MARK: - Collection Reference
  
  var collectionRef: CollectionReference {
    let db = Firestore.firestore()
    
    switch self {
    case .todos, .todo:
      return db.collection("todos")
    }
  }
  
  var documentRef: DocumentReference? {
    switch self {
    case .todos:
      return nil
    case .todo(let id):
      return collectionRef.document(id)
    }
  }
  
  // MARK: - Path
  
  var path: String {
    switch self {
    case .todos:
      return "todos"
    case .todo(let id):
      return "todos/\(id)"
    }
  }
  
}
