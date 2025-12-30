//
//  Todo.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation
import FirebaseFirestore

struct Todo: Identifiable {
  
  // MARK: - Properties
  
  var id: String?
  var clientId: String
  var title: String
  var completed: Bool
  var createdAt: Date
  var updatedAt: Date

  var isUploading: Bool = false
  
  // MARK: - Init
  
  init(id: String? = nil,
       clientId: String,
       title: String,
       completed: Bool,
       createdAt: Date,
       updatedAt: Date) {
    self.id = id
    self.clientId = clientId
    self.title = title
    self.completed = completed
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }
  
  static func create(title: String) -> Todo {
    let now = Date()
    return Todo(id: nil, clientId: UUID().uuidString,
                title: title, completed: false, createdAt: now, updatedAt: now)
  }
  
  static func createWithTempId(title: String) -> Todo {
    let now     = Date()
    let uuidStr = UUID().uuidString
    return Todo(id: "temp_\(uuidStr)", clientId: uuidStr,
                title: title, completed: false, createdAt: now, updatedAt: now)
  }
  
  var hasTempId: Bool { id?.hasPrefix("temp_") ?? false }
}


extension Todo: Codable {

  enum CodingKeys: String, CodingKey {
    case id
    case clientId
    case title
    case completed
    case createdAt
    case updatedAt
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    id = try container.decodeIfPresent(String.self, forKey: .id)
    clientId = try container.decode(String.self, forKey: .clientId)
    title = try container.decode(String.self, forKey: .title)
    completed = try container.decode(Bool.self, forKey: .completed)
    createdAt = try container.decode(Date.self, forKey: .createdAt)
    updatedAt = try container.decode(Date.self, forKey: .updatedAt)
  }
  
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encodeIfPresent(id, forKey: .id)
    try container.encode(clientId, forKey: .clientId)
    try container.encode(title, forKey: .title)
    try container.encode(completed, forKey: .completed)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(updatedAt, forKey: .updatedAt)
  }
}

// MARK: - Firestore Extension

extension Todo {
  func toDictionary() -> [String: Any] {
    return [
      "clientId": clientId,
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
    
    let clientId = (data["clientId"] as? String) ?? UUID().uuidString

    return Todo(
      id: document.documentID,
      clientId: clientId,
      title: title,
      completed: completed,
      createdAt: createdAt,
      updatedAt: updatedAt
    )
  }
  
}
