class OESettingsPrimaryTableItem {
  let path: IndexPath
  let name: String
  fileprivate let vc: UIViewController?
  fileprivate let handler: ((UISplitViewController, UITableViewController)->())?
  
  init(indexPath: IndexPath, title: String, viewController: UIViewController) {
    path = indexPath
    name = title
    vc = viewController
    handler = nil
  }
  
  init(indexPath: IndexPath, title: String, selectionHandler: @escaping (UISplitViewController, UITableViewController)->()) {
    path = indexPath
    name = title
    vc = nil
    handler = selectionHandler
  }
  
  func handleItemTouched(splitVC: UISplitViewController, tableVC: UITableViewController) {
    if vc != nil {
      splitVC.showDetailViewController(vc!, sender: nil)
    } else if handler != nil {
      handler!(splitVC, tableVC)
    }
  }
}
