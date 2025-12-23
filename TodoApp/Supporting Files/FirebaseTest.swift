//
//  Untitled.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation
import FirebaseFirestore

class FirebaseTest {
  static func testConnection() {
    let db = Firestore.firestore()
    
    let testData: [String: Any] = [
      "title": "測試項目",
      "completed": false,
      "timestamp": Date()
    ]
    
    db.collection("todos").addDocument(data: testData) { error in
      if let error = error {
        print("❌ Firebase 連線失敗：\(error.localizedDescription)")
      } else {
        print("✅ Firebase 連線成功！")
      }
    }
  }
}
