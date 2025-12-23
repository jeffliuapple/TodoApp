//
//  NetworkError.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import Foundation

enum NetworkError: Error {
  case unknown
  case firestoreError(Error)
  case encodingFailed
  case decodingFailed
  case documentNotFound
  case invalidData
  case permissionDenied
  case networkUnavailable
}

extension NetworkError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .unknown:
      return "未知錯誤"
    case .firestoreError(let error):
      return "資料庫錯誤：\(error.localizedDescription)"
    case .encodingFailed:
      return "資料編碼失敗"
    case .decodingFailed:
      return "資料解析失敗"
    case .documentNotFound:
      return "找不到資料"
    case .invalidData:
      return "資料格式錯誤"
    case .permissionDenied:
      return "沒有權限"
    case .networkUnavailable:
      return "網路連線失敗"
    }
  }
}
