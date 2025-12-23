## 專案結構
```
TodoApp/
├── README.md
├── TodoApp.xcodeproj
│
└── TodoApp/
    ├── Controllers/
    │   └── TodoListViewController.swift   # 主畫面控制器
    │
    ├── Models/
    │   └── Todo.swift                     # 資料模型
    │
    ├── Resources/
    │   └── Assets.xcassets                # 圖片資源
    │
    ├── Services/
    │   └── Networking/
    │       ├── FirebaseEndpoint.swift     # API 路徑管理
    │       ├── NetworkError.swift         # 錯誤定義
    │       └── TodoService.swift          # API 服務封裝
    │
    ├── Supporting Files/
    │   ├── AppDelegate.swift              # App 生命週期
    │   ├── FirebaseTest.swift             # Firebase 連線測試
    │   ├── GoogleService-Info.plist       # Firebase 設定
    │   ├── PrintManager.swift             # 輔助工具
    │   └── SceneDelegate.swift            # Scene 管理
    │
    ├── Views/
    │   ├── LaunchScreen.storyboard        # 啟動畫面
    │   ├── Main.storyboard                # 主要介面
    │   ├── TodoCell.swift                 # 自定義 Cell
    │   └── TodoCell.xib                   # Cell 介面設計
    │
    └── Info.plist                         # App 設定檔
```

## 架構說明

### 檔案組織原則

#### 1. Controllers 層
- **TodoListViewController.swift**
  - 負責 UI 邏輯和用戶互動
  - 處理 TableView delegate/dataSource
  - 協調 View 和 Service 之間的溝通
  - 使用 IBOutlet 連接 Storyboard 元件

#### 2. Models 層
- **Todo.swift**
  - 定義資料結構
  - 實作 Codable 協議
  - 支援 Firestore 轉換
  - 提供便利的初始化方法

#### 3. Services 層
專案採用 **Service 層** 模式，將網路邏輯獨立封裝：
```
Services/
└── Networking/
    ├── NetworkError.swift       # 統一錯誤處理
    ├── FirebaseEndpoint.swift   # 路徑管理
    └── TodoService.swift        # API 操作
```

**優點**：
- 網路邏輯與 UI 分離
- 容易測試
- 方便複用
- 符合單一職責原則

#### 4. Views 層
專案採用 **混合開發模式**：

**Main.storyboard**
- 主要畫面的佈局
- ViewController 的容器
- 使用 IBOutlet 連接：
  - `tableView` - 待辦事項列表
  - `loadingIndicator` - 載入指示器
  - `emptyStateLabel` - 空狀態提示
- 使用 IBAction 連接：
  - `refreshBtnTapped` - 重新整理按鈕
  - `addBtnTapped` - 新增按鈕

**TodoCell.xib**
- 自定義 Cell 的介面設計
- 使用 XIB 設計 UI 佈局
- 透過 `TodoCell.swift` 程式化控制

**TodoCell.swift**
- Cell 的邏輯實作
- 處理資料顯示（`configure` 方法）
- 管理 UI 狀態

#### 5. Supporting Files
- **AppDelegate.swift**：App 啟動和生命週期
- **SceneDelegate.swift**：Scene 管理（iOS 13+）
- **GoogleService-Info.plist**：Firebase 設定
- **FirebaseTest.swift**：Firebase 連線測試工具

### 資料流架構
```
┌─────────────┐
│    User     │  點擊、輸入
└──────┬──────┘
       ↓
┌──────────────────────────┐
│  Main.storyboard         │  UI 介面
│  - TableView             │  
│  - Loading Indicator     │
│  - Empty State Label     │
└──────────┬───────────────┘
           ↓ IBOutlet/IBAction
┌──────────────────────────┐
│  TodoListViewController  │  控制器邏輯
│  (Controllers)           │  - 處理用戶操作
│                          │  - 更新 UI 狀態
└──────────┬───────────────┘
           ↓
┌──────────────────────────┐
│     TodoService          │  業務邏輯
│  (Services/Networking)   │  - CRUD 操作
│                          │  - 錯誤處理
└──────────┬───────────────┘
           ↓
┌──────────────────────────┐
│   FirebaseEndpoint       │  路徑管理
│  (Services/Networking)   │  - Collection 參考
│                          │  - Document 參考
└──────────┬───────────────┘
           ↓
┌──────────────────────────┐
│  Firebase Firestore      │  雲端資料庫
│  (Cloud)                 │  - 儲存資料
│                          │  - 即時同步
└──────────────────────────┘
```

### 設計模式

#### 1. MVC 架構
```
Model（Todo.swift）
  ↑
Controller（TodoListViewController.swift）
  ↑ IBOutlet/IBAction
View（Main.storyboard + TodoCell.xib）
```

**當前實作**：
- ✅ Model 職責清楚
- ✅ View 透過 Storyboard/XIB 設計
- ✅ Controller 使用 IBOutlet/IBAction 連接
- ✅ Service 層分離網路邏輯

#### 2. Service 層模式
將所有網路請求封裝在 `TodoService`：
```swift
class TodoService {
    func fetchTodos(completion: ...)
    func createTodo(_ todo: Todo, completion: ...)
    func updateTodo(_ todo: Todo, completion: ...)
    func deleteTodo(id: String, completion: ...)
    func toggleTodo(id: String, completion: ...)
}
```

**優點**：
- 單一職責：只負責資料存取
- 容易 Mock：方便單元測試
- 可重用：其他 Controller 也能用
- 易維護：修改 API 只改這裡

#### 3. Endpoint 模式
集中管理所有 Firebase 路徑：
```swift
enum FirebaseEndpoint {
    case todos                    // Collection
    case todo(id: String)         // Document
    
    var collectionRef: CollectionReference
    var documentRef: DocumentReference?
}
```

**優點**：
- 型別安全：避免拼錯路徑
- 集中管理：容易維護
- 環境切換：Dev/Prod 輕鬆切換
- 可測試：方便 Mock

### UI 開發方式

#### Storyboard + XIB 混合開發

**為什麼用 Storyboard？**
1. **視覺化設計**
   - 直觀的拖拉操作
   - 快速原型設計
   - 容易理解畫面結構

2. **IBOutlet/IBAction**
   - 視覺化連接 UI 元件
   - 清楚的介面定義
   - 降低錯誤機會

**為什麼用 XIB？**
1. **Cell 複用**
   - 單獨設計 Cell 介面
   - 方便調整佈局
   - 可在不同 TableView 使用

2. **關注點分離**
   - Cell UI 獨立於 ViewController
   - 易於維護和修改

**程式碼範例**：
```swift
// ViewController 中註冊 XIB
tableView.register(
    UINib(nibName: TodoCell.identifier, bundle: nil),
    forCellReuseIdentifier: TodoCell.identifier
)

// 使用時直接 dequeue
let cell = tableView.dequeueReusableCell(
    withIdentifier: TodoCell.identifier, 
    for: indexPath
) as? TodoCell
```

### IBOutlet/IBAction 連接

#### 主要連接：
```swift
// UI 元件連接
@IBOutlet weak var tableView: UITableView!
@IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
@IBOutlet weak var emptyStateLabel: UILabel!

// 按鈕動作連接
@IBAction func refreshBtnTapped(_ sender: UIBarButtonItem)
@IBAction func addBtnTapped(_ sender: UIBarButtonItem)
```

**優點**：
- 清楚標記哪些是來自 Storyboard
- 編譯時期檢查連接
- 視覺化編輯器支援

### 專案特色

#### ✅ 已實作
- **Storyboard UI**：視覺化介面設計
- **XIB Cell**：可重用的 Cell 設計
- **Service 層**：網路邏輯分離
- **Endpoint 模式**：路徑集中管理
- **錯誤處理**：統一的錯誤類型
- **Firebase 整合**：真實的雲端儲存
- **自動佈局**：支援不同螢幕尺寸

#### 🚧 計畫中
- **MVVM 重構**：更清晰的架構
- **本地快取**：UserDefaults/CoreData
- **資料同步**：本地與雲端同步
- **單元測試**：提高程式碼品質
- **SwiftUI 版本**：體驗新技術

### 程式碼亮點

#### 1. 非同步處理
```swift
todoService.fetchTodos { [weak self] result in
    guard let self else { return }
    
    DispatchQueue.main.async {  // 確保 UI 更新在主執行緒
        switch result {
        case .success(let todos):
            self.todos = todos
            self.updateUI()
        case .failure(let error):
            self.showError(error.localizedDescription)
        }
    }
}
```

#### 2. 記憶體管理
- 使用 `[weak self]` 避免循環參考
- `guard let self else { return }` 安全處理

#### 3. 錯誤處理
- 統一的錯誤顯示方式
- 友善的錯誤訊息
- 不會 crash，優雅降級

#### 4. UI 更新優化
```swift
// 只更新需要的 Cell，不重新載入整個 TableView
self.todos[indexPath.row].completed.toggle()
guard let cell = self.tableView.cellForRow(at: indexPath) as? TodoCell else { return }
cell.configure(with: self.todos[indexPath.row])
```
