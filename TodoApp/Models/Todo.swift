//
//  Todo.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation
import FirebaseFirestore

struct Todo: Codable, Identifiable {
  
  // MARK: - Properties
  
  @DocumentID var id: String?
  
  var title: String
  var completed: Bool
  var createdAt: Date
  var updatedAt: Date
  
  // MARK: - Coding Keys

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case completed
    case createdAt
    case updatedAt
  }
  
  // MARK: - Init
  
  init(id: String? = nil,
       title: String,
       completed: Bool,
       createdAt: Date,
       updatedAt: Date) {
    self.id = id
    self.title = title
    self.completed = completed
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  static func create(title: String) -> Todo {
    return Todo(title: title, completed: false, createdAt: Date(), updatedAt: Date())
  }
}


// MARK: - Firestore Extension

extension Todo {
  func toDictionary() -> [String: Any] {
    return [
      "title" : title,
      "completed": completed,
      "createdAt": Timestamp(date: createdAt),
      "updatedAt": Timestamp(date: updatedAt)
    ]
  }
  
  static func fromDocument(_ document: DocumentSnapshot) -> Todo? {
    guard let data = document.data(),
          let title = data["title"] as? String,
          let completed = data["completed"] as? Bool,
          let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
          let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
    else {
      return nil
    }
    
    return Todo(
      id: document.documentID,
      title: title,
      completed: completed,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
  
}
