import Foundation

/// UITableView to display or add library accounts that the user
/// can then log in and adjust settings after selecting Accounts.
@objcMembers class NYPLDeveloperSettingsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
  weak var tableView: UITableView!
  
  required init() {
    super.init(nibName: nil, bundle: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(customLibraryListChanged), name: NSNotification.Name.NYPLCustomLibraryListDidChange, object: nil)
  }
  
  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: Callbacks
  
  func librarySwitchDidChange(sender: UISwitch!) {
    NYPLSettings.shared.useBetaLibraries = sender.isOn
  }
  
  func addCustomLibrary(sender: UIButton!) {
    var url = ""
    var parent = sender.superview
    while parent != nil {
      if parent!.isKind(of: UITableViewCell.self) {
        break
      }
      parent = parent?.superview
    }
    if parent != nil {
      let tableCellView = parent as! UITableViewCell
      if tableCellView.contentView.subviews.count > 0 {
        let subview = tableCellView.contentView.subviews[0]
        if (subview.isKind(of: UITextField.self)) {
          url = (subview as! UITextField).text ?? ""
          subview.resignFirstResponder()
        }
      }
    }
    AccountsManager.shared.addCustomAccount(url: url, viewToPresentAuthOn: self)
  }
  
  func removeCustomLibrary(sender: UIButtonWithUserData!) {
    if sender.userData != nil {
      AccountsManager.shared.removeCustomAccount(url: sender.userData as! String)
    } else {
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
  }
  
  // MARK: Cell Rendering
  
  func cellForBetaLibraries() -> UITableViewCell {
    let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "betaLibraryCell")
    cell.selectionStyle = .none
    cell.textLabel?.text = "Enable test libraries"
    let betaLibrarySwitch = UISwitch.init()
    betaLibrarySwitch.setOn(NYPLSettings.shared.useBetaLibraries, animated: false)
    betaLibrarySwitch.addTarget(self, action:#selector(librarySwitchDidChange), for:.valueChanged)
    cell.accessoryView = betaLibrarySwitch
    return cell
  }
  
  func cellForAddCustomLibrary() -> UITableViewCell {
    let cell = UITableViewCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "addCustomLibraryCell")
    cell.selectionStyle = .none
    let submitBtn = UIButton.init(frame: CGRect.init(x: 0, y: 0, width: cell.bounds.height, height: cell.bounds.height))
    if let image = UIImage.init(named: "CheckboxOn") {
      submitBtn.setImage(image, for: .normal)
    }
    submitBtn.addTarget(self, action: #selector(addCustomLibrary), for: .primaryActionTriggered)
    submitBtn.backgroundColor = .green
    cell.accessoryView = submitBtn
    let contentBounds = cell.contentView.bounds
    let textField = UITextField.init(frame: CGRect.init(x: 10, y: 5, width: contentBounds.width - 10, height: contentBounds.height - 5))
    textField.contentVerticalAlignment = .center
    textField.placeholder = "Custom OPDS Feed URL"
    cell.contentView.addSubview(textField)
    
    // Setting these button groups fixes a constraint problem
    // https://stackoverflow.com/a/46942665/9964065
    textField.inputAssistantItem.leadingBarButtonGroups = []
    textField.inputAssistantItem.trailingBarButtonGroups = []
    
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 15.0).isActive = true
    textField.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor).isActive = true
    textField.centerYAnchor.constraint(equalTo: cell.contentView.centerYAnchor).isActive = true
    
    return cell
  }
  
  func cellForCustomLibraryAt(index: Int) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    let accounts = AccountsManager.shared.userAddedAccounts
    if index < accounts.count {
      let account = accounts[index]
      cell.textLabel?.text = account.name
      let removeBtn = UIButtonWithUserData.init(frame: CGRect.init(x: 0, y: 0, width: cell.bounds.height, height: cell.bounds.height))
      if let image = UIImage.init(named: "CheckboxOff") {
        removeBtn.setImage(image, for: .normal)
      }
      removeBtn.addTarget(self, action: #selector(removeCustomLibrary), for: .primaryActionTriggered)
      removeBtn.backgroundColor = .red
      removeBtn.userData = account.catalogUrl
      cell.accessoryView = removeBtn
    }
    return cell
  }
  
  // MARK: UIViewController
  
  override func loadView() {
    self.view = UITableView(frame: CGRect.zero, style: .grouped)
    self.tableView = self.view as? UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    self.tableView.rowHeight = UITableView.automaticDimension
    self.tableView.estimatedRowHeight = UITableView.automaticDimension
    
    self.title = NSLocalizedString("Testing", comment: "Developer Settings")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else if section == 1 {
      return 1
    } else if section == 2 {
      return AccountsManager.shared.userAddedAccounts.count
    }
    return 0
  }
  
  func numberOfSections(in tableView: UITableView) -> Int {
    return 3
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if indexPath.section == 0 {
      return cellForBetaLibraries()
    } else if indexPath.section == 1 {
      return cellForAddCustomLibrary()
    } else if indexPath.section == 2 {
      return cellForCustomLibraryAt(index: indexPath.row)
    }
    return UITableViewCell.init()
  }
  
  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    switch section {
    case 0:
      return "Library Settings"
    case 1:
      return "Add Library"
    case 2:
      return "User-Added Libraries"
    default:
      return ""
    }
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    self.tableView.deselectRow(at: indexPath, animated: true)
  }
  
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
  
  func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    return 80
  }
  
  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    return false
  }
  
  // MARK: Observers
  
  func customLibraryListChanged(notification: NSNotification) {
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
}
