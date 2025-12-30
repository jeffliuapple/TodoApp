//
//  TodoListViewController.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import UIKit

class TodoListViewController: UIViewController {
  
  // MARK: - Properties
  
  private let viewModel = TodoListViewModel()

  private let refreshControl = UIRefreshControl()
  
  // MARK: - UI Components

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
  @IBOutlet weak var emptyStateLabel: UILabel!
  
  // MARK: - Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()
    
    setupUI()
    setupBindings()
    viewModel.loadTodos()
    
    setupRefreshControl()
  }
  
  // MARK: Private methods
  
  private func setupUI() {
    tableView.delegate   = self
    tableView.dataSource = self
    
    tableView.estimatedRowHeight = 50
    tableView.register(UINib(nibName: TodoCell.identifier, bundle: nil),
                       forCellReuseIdentifier: TodoCell.identifier)
  }
  
  private func setupBindings() {
    
    viewModel.onLoadingStateChanged = { [weak self] isLoading in
      DispatchQueue.main.async {
        if isLoading {
          self?.loadingIndicator.startAnimating()
        } else {
          self?.loadingIndicator.stopAnimating()
          self?.refreshControl.endRefreshing()
        }
      }
    }
    
    viewModel.onTodosUpdated = { [weak self] todos in
      DispatchQueue.main.async {
        self?.tableView.reloadData()
        self?.refreshControl.endRefreshing()
      }
    }
    
    viewModel.onEmptyStateChanged = { [weak self] isEmpty in
      DispatchQueue.main.async {
        self?.emptyStateLabel.isHidden = !isEmpty
      }
    }
    
    viewModel.onError = { [weak self] errorMessage in
      DispatchQueue.main.async {
        self?.showError(errorMessage)
        self?.refreshControl.endRefreshing()
      }
    }
  }
  
  private func setupRefreshControl() {
    refreshControl.tintColor = .systemBlue
    refreshControl.attributedTitle = NSAttributedString(
      string: "下拉重新整理...",
      attributes: [.foregroundColor: UIColor.gray]
    )
    
    refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
    tableView.refreshControl = refreshControl
  }
  
  @objc private func handleRefresh() {
    viewModel.loadTodos()
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
    viewModel.loadTodos()
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
      self?.viewModel.createTodo(title: title)
    })
    
    present(alert, animated: true)
  }

}

// MARK: - UITableViewDataSource

extension TodoListViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    viewModel.todosCount
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: TodoCell.identifier, for: indexPath) as? TodoCell,
          let todo = viewModel.todo(at: indexPath.row) else {
      return UITableViewCell()
    }
    
    cell.configure(with: todo)
    
    return cell
  }

}

// MARK: - UITableViewDelegate

extension TodoListViewController: UITableViewDelegate {
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    viewModel.heightForRow
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
    
    viewModel.toggleTodo(at: indexPath)
  }
  
  func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    if editingStyle == .delete {
      viewModel.deleteTodo(at: indexPath)
    }
  }
  
}
