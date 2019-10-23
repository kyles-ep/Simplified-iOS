class OEEULAViewController : UIViewController, UIWebViewDelegate {
  static let onlineEULAPath = "http://www.librarysimplified.org/openebookseula.html"
  static let offlineEULAPathComponent = "eula.html"
  
  private var handler: (()->Void)
  private let webView: UIWebView
  private let activityIndicatorView: UIActivityIndicatorView
  
  
  init(completionHandler: @escaping ()->Void) {
    self.handler = completionHandler
    self.title = NSLocalizedString("EULA", comment: "")
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  // MARK: UIViewController
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if NYPLSettings.shared.
  }
}
