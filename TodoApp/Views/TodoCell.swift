//
//  TodoCell.swift
//  TodoApp
//
//  Created by Jeffrey on 2025/12/23.
//

import UIKit

class TodoCell: UITableViewCell {
  
  static let identifier = "TodoCell"
    
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    setupUI()
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    
    // Configure the view for the selected state
  }
  
  private func setupUI() {
    
  }
  
  // MARK: - Configure
  
  // TODO: Mock data.
  func configure(with todo: Todo) {

    statusLabel.text = todo.completed ? "✓" : "○"
    
    let attributes: [NSAttributedString.Key: Any]
    
    if todo.completed {
      attributes = [
        .strikethroughStyle: NSUnderlineStyle.single.rawValue,
        .foregroundColor: UIColor.gray
      ]
    } else {
      attributes = [
        .strikethroughStyle: 0,
        .foregroundColor: UIColor.label
      ]
    }
    
    titleLabel.attributedText = NSAttributedString(
      string: todo.title,
      attributes: attributes
    )
  }

  // MARK: - Reuse
  
  override func prepareForReuse() {
    super.prepareForReuse()
    
    titleLabel.attributedText = nil
    statusLabel.text = nil
  }
  
}
