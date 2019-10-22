class OETutorialChoiceViewController : UIViewController {
  var completionHandler: ()->Void
  
  var descriptionLabel: UILabel
  var enterCodeButton: UIButton
  var loginWithCleverButton: UIButton
  var requestCodesButton: UIButton
  var stackView: UIStackView
  
  // MARK: UIViewController
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.title = NSLocalizedString("Log In", comment: "")
    
    self.descriptionLabel = UILabel.init(frame: CGRect.zero)
    self.descriptionLabel.font = UIFont.systemFont(ofSize: 20.0)
    self.descriptionLabel.text = NSLocalizedString("TutorialChoiceViewControllerDescription", comment: "")
    self.descriptionLabel.textAlignment = .center
    self.descriptionLabel.numberOfLines = 0
    self.descriptionLabel.sizeToFit()
    
    self.enterCodeButton = UIButton.init(type: .custom)
    self.enterCodeButton.setImage(UIImage.init(named: "FirstbookLoginButton"), for: .normal)
    self.enterCodeButton.addTarget(self, action: #selector(didSelectEnterCodes), for: .touchUpInside)
    self.enterCodeButton.sizeToFit()
    
    self.loginWithCleverButton = UIButton.init(type: .custom)
    self.loginWithCleverButton.setImage(UIImage.init(named: "CleverLoginButton"), for: .normal)
    self.loginWithCleverButton.addTarget(self, action: #selector(didSelectClever), for: .touchUpInside)
    self.loginWithCleverButton.sizeToFit()
    
    self.requestCodesButton = UIButton.init(type: .system)
    self.requestCodesButton.titleLabel?.font = UIFont.systemFont(ofSize: 20.0)
    self.requestCodesButton.setTitle(NSLocalizedString("TutorialChoiceRequestCodes", comment: ""), for: .normal)
    self.requestCodesButton.addTarget(self, action: #selector(didSelectRequestCodes), for: .touchUpInside)
    self.requestCodesButton.sizeToFit()
    
    self.stackView = UIStackView.init(arrangedSubviews: [
      self.descriptionLabel,
      self.enterCodeButton,
      self.loginWithCleverButton
    ])
    self.stackView.axis = .vertical
    self.stackView.distribution = .equalSpacing
    self.view.addSubview(self.stackView)
  }
  
  override func viewWillLayoutSubviews() {
    let minSize = min(self.view.frame.width, 414)
    
    // Magic number usage
    self.stackView.frame = CGRect.init(x: 0, y: 0, width: minSize, height: 160.0)
    self.stackView.centerInSuperview()
    self.stackView.integralizeFrame()
  }
  
  // MARK: -
  @objc func didSelectEnterCodes() {
    
  }
  
  @objc func didSelectClever() {
    
  }
  
  @objc func didSelectRequestCodes() {
    UIApplication.shared.openURL(OEConfiguration.openEBooksRequestCodesURL)
  }
}
//
//- (void)didSelectRequestCodes
//{
//  [[UIApplication sharedApplication] openURL:[NYPLConfiguration openEBooksRequestCodesURL]];
//}
//
//- (void)didSelectClever
//{
//  [[NYPLAccount sharedAccount] removeAll];
//  [CleverLoginViewController loginWithCompletionHandler:^{
//
//    [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
//    [self dismissViewControllerAnimated:YES completion:nil];
//
//    [NYPLSettings sharedSettings].userFinishedTutorial = YES;
//    NYPLAppDelegate *const appDelegate = [UIApplication sharedApplication].delegate;
//    appDelegate.window.rootViewController = [NYPLRootTabBarController sharedController];
//
//    void (^handler)() = self.completionHandler;
//    self.completionHandler = nil;
//    if(handler) handler();
//
//  }];
//}
//
//- (void)didSelectEnterCodes
//{
//  [[NYPLAccount sharedAccount] removeBarcodeAndPIN];
//  [NYPLSettingsLoginViewController
//   requestCredentialsUsingExistingBarcode:NO
//   completionHandler:^{
//
//     [self.view.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
//     [self dismissViewControllerAnimated:YES completion:nil];
//
//     [NYPLSettings sharedSettings].userFinishedTutorial = YES;
//     NYPLAppDelegate *const appDelegate = [UIApplication sharedApplication].delegate;
//     appDelegate.window.rootViewController = [NYPLRootTabBarController sharedController];
//
//     void (^handler)() = self.completionHandler;
//     self.completionHandler = nil;
//     if(handler) handler();
//
//   }];
//}
//
//+ (void)showLoginPickerWithCompletionHandler:(void (^)())handler
//{
//  NYPLTutorialChoiceViewController *const choiceViewController = [[self alloc] init];
//
//  choiceViewController.completionHandler = handler;
//
//  [choiceViewController view];
//
//  UIBarButtonItem *const cancelBarButtonItem =
//  [[UIBarButtonItem alloc]
//   initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
//   target:choiceViewController
//   action:@selector(didSelectCancel)];
//
//  choiceViewController.navigationItem.leftBarButtonItem = cancelBarButtonItem;
//
//  UIViewController *const viewController = [[UINavigationController alloc]
//                                            initWithRootViewController:choiceViewController];
//  viewController.modalPresentationStyle = UIModalPresentationFormSheet;
//  viewController.view.backgroundColor = [UIColor whiteColor];
//
//  [(NYPLAppDelegate *)[UIApplication sharedApplication].delegate
//   safelyPresentViewController:viewController
//   animated:YES
//   completion:nil];
//
//}
//
//- (void)didSelectCancel
//{
//
//  [self.navigationController.presentingViewController
//   dismissViewControllerAnimated:YES
//   completion:nil];
//}
//
//
//@end
