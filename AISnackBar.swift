import UIKit

enum Style {
    case error
    case warning
    case info
    case success
    
    var color: UIColor {
        switch self {
        case .error:
            return .red
        case .warning:
            return .yellow
        case .info:
            return .blue
        case .success:
            return .green
        }
    }
    
    var icon: UIImage? {
        return nil
    }
}

fileprivate protocol AISnackBarDelegate {
    func dissmiss()
}

class SnackBarView: UIView {
    @IBOutlet private var iconImageView: UIImageView!
    @IBOutlet private var label: UILabel!
    @IBOutlet weak var baseView: UIView!
    @IBOutlet weak var safeAreaTopConstraint: NSLayoutConstraint!
    
    fileprivate var delegate: AISnackBarDelegate?
    
    var handler: (()->())?
    
    static func createWithStyle(_ style: Style, text: String?, attributtedText: NSAttributedString?) -> SnackBarView {
        let sbView = loadViewFromNib()
        
        if let text = text {
            sbView.label.text = text
        } else {
            sbView.label.attributedText = attributtedText
        }
        
        sbView.backgroundColor = style.color
        sbView.iconImageView.image = style.icon
        
        return sbView
    }
    
    func setupGestureRecognizer(handler: @escaping ()->()) {
        self.handler = handler
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapGestureHandler)))
    }
    
    @objc func tapGestureHandler() {
        handler?()
        dismiss()
    }
    
    override func draw(_ rect: CGRect) {
        addShadow()
    }
    
    private static func loadViewFromNib() -> SnackBarView {
        return UINib(nibName: String(describing: Self.self), bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! SnackBarView
    }
    
    func addShadow() {
        self.layer.masksToBounds = false
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOpacity = 0.16
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 10
        self.layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        self.layer.shouldRasterize = true
        self.layer.rasterizationScale = UIScreen.main.scale
    }
    
    @IBAction private func dismiss() {
        delegate?.dissmiss()
        handler = nil
    }
}

class SnackBarViewController: UIViewController {
    var viewWillAppear: (()->())?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewWillAppear?()
    }
}

class AISnackBar {
    static let autoHideAfter = 5.0
    
    private static let current: AISnackBar = AISnackBar()
    private var window: UIWindow
    
    private init() {
        window = UIWindow()
        window.windowLevel = .alert

    }
    
    static func show(text: String?, attributtedText: NSAttributedString? = nil, style: Style, autoHide: Bool = true, tapHandler: (()->())? = nil) {
        let vc = SnackBarViewController()
        current.window.rootViewController = vc

        DispatchQueue.main.async {
            let window = AISnackBar.current.window
            window.clipsToBounds = true
            
            let view = SnackBarView.createWithStyle(style, text: text, attributtedText: attributtedText)
            
            if let tapHandler = tapHandler {
                view.setupGestureRecognizer(handler: tapHandler)
            }
            
            window.backgroundColor = view.backgroundColor
            
            window.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 0)
            
            view.delegate = AISnackBar.current
            
            let tag = Int.random(in: 0..<Int.max)
            view.tag = tag
            
            let vc = window.rootViewController as! SnackBarViewController
            
            vc.viewWillAppear = {
                var topSafeArea: CGFloat = 0
                if #available(iOS 11.0, *) {
                    topSafeArea = UIApplication.shared.windows.first?.safeAreaInsets.top ?? 0
                }
                
                view.safeAreaTopConstraint.constant = topSafeArea
                
                var newFrame = (vc.view as! SnackBarView).baseView.bounds
                newFrame.size.height = newFrame.size.height + topSafeArea
                
                UIView.animate(withDuration: 0.1, animations: {
                    window.frame = newFrame
                })
            }
            
            window.rootViewController?.view = view
            window.isHidden = false
            
            let deadlineTime = DispatchTime.now() + autoHideAfter
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                self.dismiss(tag: tag)
            }
        }
    }
    
    static func dismiss() {
        let window = AISnackBar.current.window
        
        window.rootViewController?.view = nil
        window.isHidden = true
    }
    
    private static func dismiss(tag: Int) {
        let window = AISnackBar.current.window
        let view = window.rootViewController?.view
        
        if view?.tag == tag {
            dismiss()
        }
    }
}

extension AISnackBar: AISnackBarDelegate {
    func dissmiss() {
        AISnackBar.dismiss()
    }
}
