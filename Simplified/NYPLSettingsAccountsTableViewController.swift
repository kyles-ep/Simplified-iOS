/// Type of library that can be added by the user
/// to log in witih.
@objc enum NYPLUserAccountType: Int {
  case NYPL = 0
  case Brooklyn
  case Magic
  
  func simpleDescription() -> String {
    switch self {
    case .NYPL:
      return "New York Public Library"
    case .Brooklyn:
      return "Brooklyn Public Library"
    case .Magic:
      return "The Magic Library"
    }
  }
}

/// UITableView to display or add libraries that the user
/// can then log in to after selecting Accounts.
class NYPLSettingsAccountsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  weak var tableView: UITableView!
  
  private var accountsList: [NYPLUserAccountType] {
    didSet {
      var array = [Int]()
      for item in accountsList { array.append(item.rawValue) }
      NYPLSettings.sharedSettings().settingsAccountsList = array
      self.updateUI()
    }
  }
  
  private var secondaryAccounts: [NYPLUserAccountType] {
    get {
      var array = [NYPLUserAccountType]()
      for account in self.accountsList {
        if (account.rawValue != self.currentLibrary.rawValue) {
          array.append(account)
        }
      }
      return array
    }
    set {
      var array = newValue
      array.append(currentLibrary)
      self.accountsList = array
    }
  }

  private var currentLibrary: NYPLUserAccountType {
    get {
      let libString = NYPLSettings.sharedSettings().currentAccount
      guard let lib = NYPLUserAccountType(rawValue: Int(libString)!) else { return NYPLUserAccountType.NYPL }
      return lib
    }
  }
  
  required init(accounts: [Int]) {
    var filteredList = [NYPLUserAccountType]()
    for item in accounts {
      guard let library = NYPLUserAccountType(rawValue: item) else { continue }
      filteredList.append(library)
    }
    self.accountsList = filteredList
    super.init(nibName:nil, bundle:nil)
  }

  @available(*, unavailable)
  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  
  override func loadView() {
    self.view = UITableView(frame: CGRectZero, style: .Grouped)
    self.tableView = self.view as! UITableView
    self.tableView.delegate = self
    self.tableView.dataSource = self
    
    self.title = NSLocalizedString("Accounts",
                                   comment: "A title for a list of libraries the user may select or add to.")
    self.view.backgroundColor = NYPLConfiguration.backgroundColor()
    
    updateUI()
  }
  
  func updateUI() {
    if (accountsList.count < 3) {
      self.navigationItem.rightBarButtonItem = UIBarButtonItem(
        barButtonSystemItem: .Add, target: self, action: #selector(addLibrary))
    } else {
      self.navigationItem.rightBarButtonItem = nil
    }
  }
  
  func addLibrary() {
    let alert = UIAlertController(title: NSLocalizedString(
      "SettingsAccountLibrariesViewControllerAlertTitle",
      comment: "Title to tell a user that they can add another library to the list"),
                                  message: nil,
                                  preferredStyle: .ActionSheet)
    alert.popoverPresentationController?.barButtonItem = self.navigationItem.rightBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .Up
    
    if (accountsList.contains(.NYPL) == false) {
      alert.addAction(UIAlertAction(title: "New York Public Library", style: .Default, handler: { action in
        self.accountsList.append(NYPLUserAccountType.NYPL)
        self.tableView.reloadData()
      }))
    }
    if (accountsList.contains(.Brooklyn) == false) {
      alert.addAction(UIAlertAction(title: "Brooklyn Public Library", style: .Default, handler: { action in
        self.accountsList.append(NYPLUserAccountType.Brooklyn)
        self.tableView.reloadData()
      }))
    }
    if (accountsList.contains(.Magic) == false) {
      alert.addAction(UIAlertAction(title: "The Magic Library", style: .Default, handler: { action in
        self.accountsList.append(NYPLUserAccountType.Magic)
        self.tableView.reloadData()
      }))
    }
    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler:nil))
    
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  // MARK: UITableViewDataSource
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if section == 0 {
      return 1
    } else if (self.accountsList.count >= 1) {
      return self.accountsList.count - 1
    } else {
      return 0
    }
  }
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 2;
  }
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if (indexPath.section == 0) {
      return cellForLibrary(self.currentLibrary, indexPath)
    } else {
      return cellForLibrary(self.secondaryAccounts[indexPath.row], indexPath)
    }
  }
  
  func cellForLibrary(library: NYPLUserAccountType, _ indexPath: NSIndexPath) -> UITableViewCell {
    let cell = UITableViewCell.init(style: .Subtitle, reuseIdentifier: "")
    cell.accessoryType = .DisclosureIndicator
    cell.textLabel?.font = UIFont(name: "AvenirNext-Regular", size: 14)
    cell.textLabel?.text = library.simpleDescription()
    
    cell.detailTextLabel?.font = UIFont(name: "AvenirNext-Regular", size: 10)
    cell.detailTextLabel?.text = "Subtitle will go here."
    
    switch library {
    case .Brooklyn:
      cell.imageView?.image = UIImage(named: "LibraryLogoBrooklyn")
    case .NYPL:
      cell.imageView?.image = UIImage(named: "LibraryLogoNYPL")
    case .Magic:
      cell.imageView?.image = UIImage(named: "LibraryLogoMagic2")
    }
    
    return cell
  }
  
  // MARK: UITableViewDelegate
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    var account: Int
    if (indexPath.section == 0) {
      account = self.currentLibrary.rawValue
    } else {
      account = self.secondaryAccounts[indexPath.row].rawValue
    }
    let viewController = NYPLSettingsAccountDetailViewController(account: account)
    self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    self.navigationController?.pushViewController(viewController, animated: true)
  }
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 60;
  }
  
  func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    if indexPath.section == 0 {
      return false;
    } else {
      return true;
    }
  }
  
  func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
      secondaryAccounts.removeAtIndex(indexPath.row)
      tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
      self.tableView.reloadData()
    }
  }
}