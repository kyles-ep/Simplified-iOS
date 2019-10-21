class SEUtils {
  func vcSwitchLibrary(context: UINavigationController) {
    let vc = context.visibleViewController
    let style = (vc != nil) ? UIAlertController.Style.actionSheet : UIAlertController.Style.alert

    let alert = UIAlertController.init(title: NSLocalizedString("PickYourLibrary", comment: ""), message: nil, preferredStyle: style)
    alert.popoverPresentationController?.barButtonItem = vc?.navigationItem.leftBarButtonItem
    alert.popoverPresentationController?.permittedArrowDirections = .up
    
    let accounts = NYPLSettings.shared.settingsAccountsList
    
    for acct in accounts {
      guard let account = AccountsManager.shared.account(acct) else {
        continue
      }
      
      alert.addAction(UIAlertAction.init(title: account.name, style: .default, handler: { (action) in
        var workflowsInProgress = NYPLBookRegistry.shared()?.syncing ?? false
#if FEATURE_DRM_CONNECTOR
        workflowsInProgress = workflowsInProgress || (NYPLADEPT.sharedInstance()?.workflowsInProgress ?? false)
#endif

        if workflowsInProgress {
          context.present(NYPLAlertUtils.alert(title: "PleaseWait", message: "PleaseWaitMessage"), animated: true, completion: nil)
        } else {
          NYPLBookRegistry.shared().save()
          account.loadAuthenticationDocument(preferringCache: true) { (success) in
            if success {
              AccountsManager.shared.currentAccount = account
              
            }
          }
          context.reloadSelected
        }
          
      }))
    }
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"ManageAccounts", nil) style:(UIAlertActionStyleDefault) handler:^(__unused UIAlertAction *_Nonnull action) {
      NSUInteger tabCount = [[[NYPLRootTabBarController sharedController] viewControllers] count];
      UISplitViewController *splitViewVC = [[[NYPLRootTabBarController sharedController] viewControllers] lastObject];
      UINavigationController *masterNavVC = [[splitViewVC viewControllers] firstObject];
      [masterNavVC popToRootViewControllerAnimated:NO];
      [[NYPLRootTabBarController sharedController] setSelectedIndex:tabCount-1];
      NYPLSettingsPrimaryTableViewController *tableVC = [[masterNavVC viewControllers] firstObject];
      [tableVC.delegate settingsPrimaryTableViewController:tableVC didSelectItem:NYPLSettingsPrimaryTableViewControllerItemAccount];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:(UIAlertActionStyleCancel) handler:nil]];
    
    [[NYPLRootTabBarController sharedController] safelyPresentViewController:alert animated:YES completion:nil];
  }
}
