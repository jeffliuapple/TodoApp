//
//  TodoListViewController.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import UIKit

class TodoListViewController: UIViewController {
  
  // MARK: - Properties

  private var todos: [Todo] = []
  private let todoService = TodoService()
  
  // MARK: - UI Components

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  
  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    loadTodos()
  }
  
  // MARK: Private methods
  
  private func setupUI() {
    tableView.delegate   = self
    tableView.dataSource = self
    
    tableView.estimatedRowHeight = 50
    tableView.rowHeight = UITableView.automaticDimension
    tableView.register(UINib(nibName: TodoCell.identifier, bundle: nil),
                       forCellReuseIdentifier: TodoCell.identifier)
  }
  
  
  private func loadTodos() {
    loadingIndicator.startAnimating()

    todoService.fetchTodos { [weak self] result in
      guard let self else { return }
      self.loadingIndicator.stopAnimating()

      DispatchQueue.main.async {
        switch result {
        case .success(let todos):
          self.todos = todos
          self.updateUI()
        case .failure(let error):
          self.showError(error.localizedDescription)
        }
      }
    }
  }
  
  private func updateUI() {
    emptyStateLabel.isHidden = !todos.isEmpty
    tableView.reloadData()
  }
  
  private func showError(_ message: String) {
    let alert = UIAlertController(
      title: "錯誤",
      message: message,
      preferredStyle: .alert
    )
    alert.addAction(UIAlertAction(title: "確定", style: .default))
    present(alert, animated: true)
  }
  
  @IBAction func refreshBtnTapped(_ sender: UIBarButtonItem) {
    loadTodos()
  }
  
  @IBAction func addBtnTapped(_ sender: UIBarButtonItem) {
    let alert = UIAlertController(
      title: "新增待辦事項",
      message: nil,
      preferredStyle: .alert
    )
    
    alert.addTextField { textField in
      textField.placeholder = "輸入待辦事項"
      textField.autocapitalizationType = .sentences
    }
    
    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
    alert.addAction(UIAlertAction(title: "新增", style: .default) { [weak self, weak alert] _ in
      guard let title = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespaces),
            !title.isEmpty else {
        return
      }
      self?.createTodo(title: title)
    })
    
    present(alert, animated: true)
  }
  
  private func createTodo(title: String) {
    let newTodo = Todo.create(title: title)
    
    todoService.createTodo(newTodo) { [weak self] result in
      DispatchQueue.main.async {
        switch result {
        case .success(let todo):
          self?.todos.insert(todo, at: 0)
          self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
          self?.updateUI()
        case .failure(let error):
          self?.showError(error.localizedDescription)
        }
      }
    }
  }
  
  private func toggleTodo(at indexPath: IndexPath) {
    guard indexPath.row < todos.count,
          let id = todos[indexPath.row].id else { return }
    todoService.toggleTodo(id: id) { [weak self] result in
      guard let self else { return }
      
      DispatchQueue.main.async {
        switch result {
        case .success():
          self.todos[indexPath.row].completed.toggle()
          guard let cell = self.tableView.cellForRow(at: indexPath) as? TodoCell else { return }
          cell.configure(with:  self.todos[indexPath.row])
        case .failure(let error):
          self.showError(error.localizedDescription)
        }
      }
    }
  }
  
  private func deleteTodo(at indexPath: IndexPath) {
    guard indexPath.row < todos.count,
          let id = todos[indexPath.row].id else { return }
    
    todoService.deleteTodo(id: id) { result in
      DispatchQueue.main.async {
        switch result {
        case .success():
          self.todos.remove(at: indexPath.row)
          self.tableView.deleteRows(at: [indexPath], with: .automatic)
          self.updateUI()
        case .failure(let error):
          self.showError(error.localizedDescription)
        }
      }
    }
  }

}

// MARK: - UITableViewDataSource

extension TodoListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    todos.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: TodoCell.identifier, for: indexPath) as? TodoCell else {
      return UITableViewCell()
    }
    
    let todo = todos[indexPath.row]
    cell.configure(with: todo)
    
    return cell
  }

}

// MARK: - UITableViewDelegate

extension TodoListViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    50.0
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    toggleTodo(at: indexPath)
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      deleteTodo(at: indexPath)
    }
  }
  
}
