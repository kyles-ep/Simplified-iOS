class SEConfiguration : NYPLConfiguration {
  static var seShared = SEConfiguration()
  
  var iconLogoBlueColor: UIColor {
    if #available(iOS 13.0, *) {
      return UIColor.init(named: "ColorIconLogoBlue") ?? UIColor.init(red: 17.0/255.0, green: 50.0/255.0, blue: 84.0/255.0, alpha: 1.0)
    }
    return UIColor.init(red: 17.0/255.0, green: 50.0/255.0, blue: 84.0/255.0, alpha: 1.0)
  }

  let iconLogoGreenColor = UIColor.init(red: 141.0/255.0, green: 199.0/255.0, blue: 64.0/255.0, alpha: 1.0)
  
  // MARK: NYPLConfiguration
}