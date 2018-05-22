//
//  FWPopupView.swift
//  FWPopupView
//
//  Created by xfg on 2018/3/19.
//  Copyright © 2018年 xfg. All rights reserved.
//

/** ************************************************
 
 github地址：https://github.com/choiceyou/FWPopupView
 bug反馈、交流群：670698309
 
 ***************************************************
 */


import Foundation
import UIKit

/// 弹窗类型
///
/// - alert: Alert类型，表示弹窗在屏幕中间
/// - sheet: Sheet类型，表示弹窗在屏幕底部
/// - custom: 自定义类型
@objc public enum FWPopupType: Int {
    case alert
    case sheet
    case custom
}

/// 自定义弹窗校准位置，注意：这边设置靠置哪边动画就从哪边出来
///
/// - center: 中间，默认值
/// - top: 上
/// - left: 左
/// - bottom: 下
/// - right: 右
/// - topLeft: 上左
/// - topRight: 上右
/// - bottomLeft: 下左
/// - bottomRight: 下右
@objc public enum FWPopupCustomAlignment: Int {
    case center
    case top
    case left
    case bottom
    case right
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
}

/// 显示、隐藏回调
public typealias FWPopupBlock = (_ popupView: FWPopupView) -> Void
/// 显示、隐藏完成回调，某些场景下可能会用到 isShow ==》true: 显示 false：隐藏
public typealias FWPopupCompletionBlock = (_ popupView: FWPopupView, _ isShow: Bool) -> Void
/// 普通无参数回调
public typealias FWPopupVoidBlock = () -> Void

/// 隐藏所有弹窗的通知
let FWPopupViewHideAllNotification = "FWPopupViewHideAllNotification"


open class FWPopupView: UIView {
    
    /// 1、当外部没有传入该参数时，默认为UIWindow的根控制器的视图，即表示弹窗放在FWPopupWindow上，此时若FWPopupWindow.sharedInstance.touchWildToHide = true表示弹窗视图外部可点击；2、当外部传入该参数时，该视图为传入的UIView，即表示弹窗放在传入的UIView上；
    @objc public var attachedView = FWPopupWindow.sharedInstance.attachView()
    
    /// FWPopupType = custom 的可设置参数
    @objc public var vProperty: FWPopupViewProperty?
    
    @objc public var visible: Bool {
        get {
            if self.attachedView != nil {
                return !(self.attachedView?.fwMaskView.isHidden)!
            }
            return false
        }
    }
    
    @objc public var popupType: FWPopupType = .alert {
        
        willSet {
            
            switch newValue {
            case .alert:
                self.showAnimation = self.alertShowAnimation()
                self.hideAnimation = self.alertHideAnimation()
                break
            case .sheet:
                self.showAnimation = self.sheetShowAnimation()
                self.hideAnimation = self.sheetHideAnimation()
                break
            case .custom:
                self.showAnimation = self.customShowAnimation()
                self.hideAnimation = self.customHideAnimation()
                break
            }
        }
    }
    
    @objc public var animationDuration: TimeInterval = 0.2 {
        willSet {
            self.attachedView?.fwAnimationDuration = newValue
        }
    }
    
    @objc public var withKeyboard = false
    
    
    private var popupCompletionBlock: FWPopupCompletionBlock?
    
    private var showAnimation: FWPopupBlock?
    
    private var hideAnimation: FWPopupBlock?
    
    /// 记录遮罩层设置前的颜色
    internal var originMaskViewColor: UIColor!
    /// 记录遮罩层设置前的是否可点击
    internal var originTouchWildToHide: Bool!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        FWPopupWindow.sharedInstance.backgroundColor = UIColor.clear
        
        self.originMaskViewColor = self.attachedView?.fwMaskViewColor
        self.originTouchWildToHide = FWPopupWindow.sharedInstance.touchWildToHide
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyHideAll(notification:)), name: NSNotification.Name(rawValue: FWPopupViewHideAllNotification), object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc open func showKeyboard() {
        
    }
    
    @objc open func hideKeyboard() {
        
    }
}

// MARK: - 显示、隐藏
extension FWPopupView {
    
    /// 显示
    @objc open func show() {
        
        self.show(completionBlock: nil)
    }
    
    /// 显示
    ///
    /// - Parameter completionBlock: 显示、隐藏回调
    @objc open func show(completionBlock: FWPopupCompletionBlock? = nil) {
        
        if completionBlock != nil {
            self.popupCompletionBlock = completionBlock
        }
        
        if self.attachedView == nil {
            self.attachedView = FWPopupWindow.sharedInstance.attachView()
        }
        
        self.attachedView?.showFwBackground()
        
        let showA = self.showAnimation
        showA!(self)
        
        if self.withKeyboard {
            self.showKeyboard()
        }
    }
    
    /// 隐藏
    @objc open func hide() {
        
        self.hide(completionBlock: nil)
    }
    
    /// 隐藏
    ///
    /// - Parameter completionBlock: 显示、隐藏回调
    @objc open func hide(completionBlock: FWPopupCompletionBlock? = nil) {
        
        if completionBlock != nil {
            self.popupCompletionBlock = completionBlock
        }
        
        if self.attachedView == nil {
            self.attachedView = FWPopupWindow.sharedInstance.attachView()
        }
        self.attachedView?.hideFwBackground()
        
        if self.withKeyboard {
            self.hideKeyboard()
        }
        
        let hideAnimation = self.hideAnimation
        if hideAnimation != nil {
            hideAnimation!(self)
        }
        
        // 还原弹窗弹起时的相关参数
        self.attachedView?.fwMaskViewColor = self.originMaskViewColor
        FWPopupWindow.sharedInstance.touchWildToHide = self.originTouchWildToHide
    }
    
    /// 隐藏所有的弹窗
    @objc open class func hideAll() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: FWPopupViewHideAllNotification), object: FWPopupView.self)
    }
    
    @objc open func notifyHideAll(notification: Notification) {
        
        if self.isKind(of: notification.object as! AnyClass) {
            self.hide()
        }
    }
    
    /// 弹窗是否隐藏
    ///
    /// - Returns: 是否隐藏
    @objc open class func isPopupViewHiden() -> Bool {
        return FWPopupWindow.sharedInstance.isHidden
    }
}

// MARK: - 动画事件
extension FWPopupView {
    
    private func alertShowAnimation() -> FWPopupBlock {
        
        let popupBlock = { [weak self] (popupView: FWPopupView) in
            
            guard let strongSelf = self else {
                return
            }
            if strongSelf.superview == nil {
                strongSelf.attachedView?.fwMaskView.addSubview(strongSelf)
                strongSelf.center = (strongSelf.attachedView?.center)!
                if strongSelf.withKeyboard {
                    strongSelf.frame.origin.y -= 216/2
                }
                strongSelf.layoutIfNeeded()
            }
            strongSelf.layer.transform = CATransform3DMakeScale(1.2, 1.2, 1.0)
            strongSelf.alpha = 0.0
            
            UIView.animate(withDuration: strongSelf.animationDuration, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                
                strongSelf.layer.transform = CATransform3DIdentity
                strongSelf.alpha = 1.0
                
            }, completion: { (finished) in
                
                if strongSelf.popupCompletionBlock != nil {
                    strongSelf.popupCompletionBlock!(strongSelf, true)
                }
                
            })
        }
        
        return popupBlock
    }
    
    private func alertHideAnimation() -> FWPopupBlock {
        
        let popupBlock:FWPopupBlock = { [weak self] popupView in
            
            guard let strongSelf = self else {
                return
            }
            UIView.animate(withDuration: strongSelf.animationDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                
                strongSelf.alpha = 0.0
                
            }, completion: { (finished) in
                
                if finished {
                    strongSelf.removeFromSuperview()
                }
                if strongSelf.popupCompletionBlock != nil {
                    strongSelf.popupCompletionBlock!(strongSelf, false)
                }
                
            })
        }
        
        return popupBlock
    }
    
    private func sheetShowAnimation() -> FWPopupBlock {
        
        let popupBlock:FWPopupBlock = { [weak self] popupView in
            
            guard let strongSelf = self else {
                return
            }
            if strongSelf.superview == nil {
                strongSelf.attachedView?.fwMaskView.addSubview(strongSelf)
                strongSelf.frame.origin.y =  UIScreen.main.bounds.height
            }
            
            UIView.animate(withDuration: strongSelf.animationDuration / 2, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                
                strongSelf.frame.origin.y =  UIScreen.main.bounds.height - strongSelf.frame.height
                strongSelf.layoutIfNeeded()
                strongSelf.superview?.layoutIfNeeded()
                
            }, completion: { (finished) in
                
                if strongSelf.popupCompletionBlock != nil {
                    strongSelf.popupCompletionBlock!(strongSelf, true)
                }
                
            })
        }
        
        return popupBlock
    }
    
    private func sheetHideAnimation() -> FWPopupBlock {
        
        let popupBlock:FWPopupBlock = { [weak self] popupView in
            
            guard let strongSelf = self else {
                return
            }
            UIView.animate(withDuration: strongSelf.animationDuration / 2, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                
                strongSelf.frame.origin.y =  UIScreen.main.bounds.height
                strongSelf.superview?.layoutIfNeeded()
                
            }, completion: { (finished) in
                
                if finished {
                    strongSelf.removeFromSuperview()
                }
                if strongSelf.popupCompletionBlock != nil {
                    strongSelf.popupCompletionBlock!(strongSelf, false)
                }
                
            })
        }
        
        return popupBlock
    }
    
    private func customShowAnimation() -> FWPopupBlock {
        
        let popupBlock = { [weak self] (popupView: FWPopupView) in
            
            guard let strongSelf = self else {
                return
            }
            
            if strongSelf.vProperty == nil {
                strongSelf.vProperty = FWPopupViewProperty()
            }
            
            let originFrame = strongSelf.frame
            
            if strongSelf.superview == nil {
                strongSelf.attachedView?.fwMaskView.addSubview(strongSelf)
                
                switch strongSelf.vProperty!.popupCustomAlignment {
                case .center:
                    strongSelf.center = strongSelf.attachedView!.center
                    strongSelf.frame.origin.x += strongSelf.vProperty!.popupViewEdgeInsets.left - strongSelf.vProperty!.popupViewEdgeInsets.right
                    strongSelf.frame.origin.y = strongSelf.vProperty!.popupViewEdgeInsets.top - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                    break
                case .top:
                    strongSelf.frame.origin.x += strongSelf.vProperty!.popupViewEdgeInsets.left - strongSelf.vProperty!.popupViewEdgeInsets.right
                    strongSelf.frame.origin.y = strongSelf.vProperty!.popupViewEdgeInsets.top
                    strongSelf.frame.size.height = 0
                    break
                case .left:
                    strongSelf.frame.origin.x = strongSelf.vProperty!.popupViewEdgeInsets.left
                    strongSelf.frame.origin.y += strongSelf.vProperty!.popupViewEdgeInsets.top - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                    strongSelf.frame.size.width = 0
                    break
                case .bottom:
                    strongSelf.frame.origin.x += strongSelf.vProperty!.popupViewEdgeInsets.left - strongSelf.vProperty!.popupViewEdgeInsets.right
                    strongSelf.frame.origin.y = strongSelf.attachedView!.frame.height - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                    strongSelf.frame.size.height = 0
                    break
                case .right:
                    strongSelf.frame.origin.x = strongSelf.attachedView!.frame.width - strongSelf.vProperty!.popupViewEdgeInsets.right
                    strongSelf.frame.origin.y += strongSelf.vProperty!.popupViewEdgeInsets.top - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                    strongSelf.frame.size.width = 0
                    break
                case .topLeft:
                    strongSelf.frame.origin.x = strongSelf.vProperty!.popupViewEdgeInsets.left
                    strongSelf.frame.origin.y = strongSelf.vProperty!.popupViewEdgeInsets.top
                    break
                case .topRight:
                    strongSelf.frame.origin.x = strongSelf.attachedView!.frame.width - strongSelf.frame.width - strongSelf.vProperty!.popupViewEdgeInsets.right
                    strongSelf.frame.origin.y = strongSelf.vProperty!.popupViewEdgeInsets.top
                    break
                case .bottomLeft:
                    strongSelf.frame.origin.x = strongSelf.vProperty!.popupViewEdgeInsets.left
                    strongSelf.frame.origin.y = strongSelf.attachedView!.frame.height - strongSelf.frame.height - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                    break
                case .bottomRight:
                    strongSelf.frame.origin.x = strongSelf.attachedView!.frame.width - strongSelf.frame.width - strongSelf.vProperty!.popupViewEdgeInsets.right
                    strongSelf.frame.origin.y = strongSelf.attachedView!.frame.height - strongSelf.frame.height - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                    break
                }
                
                if strongSelf.vProperty!.popupCustomAlignment == .center {
                    
                    strongSelf.transform = CGAffineTransform.init(scaleX: 0.01, y: 0.01)
                    
                } else if strongSelf.vProperty!.popupCustomAlignment.rawValue >= FWPopupCustomAlignment.top.rawValue && strongSelf.vProperty!.popupCustomAlignment.rawValue <= FWPopupCustomAlignment.right.rawValue {
                    
                } else {
                    strongSelf.layer.anchorPoint = CGPoint(x: 0.5, y: ( strongSelf.vProperty!.popupCustomAlignment == .topLeft || strongSelf.vProperty!.popupCustomAlignment == .topRight ? 0 : 1))
                    strongSelf.frame = originFrame
                    
                    strongSelf.transform = CGAffineTransform.init(scaleX: 0.01, y: 0.01)
                }
                
                strongSelf.layoutIfNeeded()
            }
            
            UIView.animate(withDuration: strongSelf.animationDuration, delay: 0.0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
                
                if strongSelf.vProperty!.popupCustomAlignment.rawValue >= FWPopupCustomAlignment.top.rawValue && strongSelf.vProperty!.popupCustomAlignment.rawValue <= FWPopupCustomAlignment.right.rawValue {
                    
                    switch strongSelf.vProperty!.popupCustomAlignment {
                    case .top:
                        strongSelf.frame.origin.y = strongSelf.vProperty!.popupViewEdgeInsets.top
                        strongSelf.frame.size.height = originFrame.height
                        break
                    case .left:
                        strongSelf.frame.origin.x = strongSelf.vProperty!.popupViewEdgeInsets.left
                        strongSelf.frame.size.width = originFrame.width
                        break
                    case .bottom:
                        strongSelf.frame.size.height = originFrame.height
                        strongSelf.frame.origin.y = strongSelf.attachedView!.frame.height - strongSelf.frame.height - strongSelf.vProperty!.popupViewEdgeInsets.bottom
                        break
                    case .right:
                        strongSelf.frame.size.width = originFrame.width
                        strongSelf.frame.origin.x = strongSelf.attachedView!.frame.width - strongSelf.frame.width - strongSelf.vProperty!.popupViewEdgeInsets.right
                        break
                    default:
                        break
                    }
                    
                } else {
                    strongSelf.transform = CGAffineTransform.identity
                }
                
                strongSelf.superview?.layoutIfNeeded()
                
            }, completion: { (finished) in
                
                if strongSelf.popupCompletionBlock != nil {
                    strongSelf.popupCompletionBlock!(strongSelf, true)
                }
                
            })
        }
        
        return popupBlock
    }
    
    private func customHideAnimation() -> FWPopupBlock {
        
        let popupBlock:FWPopupBlock = { [weak self] popupView in
            
            guard let strongSelf = self else {
                return
            }
            UIView.animate(withDuration: strongSelf.animationDuration, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
                
                strongSelf.superview?.layoutIfNeeded()
                
            }, completion: { (finished) in
                
                if finished {
                    strongSelf.removeFromSuperview()
                }
                if strongSelf.popupCompletionBlock != nil {
                    strongSelf.popupCompletionBlock!(strongSelf, false)
                }
                
            })
        }
        
        return popupBlock
    }
    
    /// 将颜色转换为图片
    ///
    /// - Parameter color: 颜色
    /// - Returns: UIImage
    public func getImageWithColor(color: UIColor) -> UIImage {
        
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}


// MARK: - 弹窗的的相关配置属性
open class FWPopupViewProperty: NSObject {
    
    // 单个点击按钮的高度
    @objc public var buttonHeight: CGFloat          = 48.0
    // 圆角值
    @objc public var cornerRadius: CGFloat          = 5.0
    
    // 标题字体大小
    @objc public var titleFontSize: CGFloat         = 18.0
    // 点击按钮字体大小
    @objc public var buttonFontSize: CGFloat        = 17.0
    
    // 弹窗的背景色（注意：这边指的是弹窗而不是遮罩层，遮罩层背景色的设置是：fwMaskViewColor）
    @objc public var backgroundColor: UIColor       = UIColor.white
    // 遮罩层的背景色（也可以使用fwMaskViewColor），注意：该参数在弹窗隐藏后，还原为弹窗弹起时的值
    @objc public var maskViewColor: UIColor?
    
    // 为了兼容OC，0表示NO，1表示YES，为YES时：用户点击外部遮罩层页面可以消失，注意：该参数在弹窗隐藏后，还原为弹窗弹起时的值
    @objc open var touchWildToHide: String?
    
    // 标题文字颜色
    @objc public var titleColor: UIColor            = kPV_RGBA(r: 51, g: 51, b: 51, a: 1)
    // 边框、分割线颜色
    @objc public var splitColor: UIColor            = kPV_RGBA(r: 231, g: 231, b: 231, a: 1)
    // 边框宽度
    @objc public var splitWidth: CGFloat            = (1/UIScreen.main.scale)
    
    // 普通按钮颜色
    @objc public var itemNormalColor: UIColor       = kPV_RGBA(r: 51, g: 51, b: 51, a: 1)
    // 高亮按钮颜色
    @objc public var itemHighlightColor: UIColor    = kPV_RGBA(r: 254, g: 226, b: 4, a: 1)
    // 选中按钮颜色
    @objc public var itemPressedColor: UIColor      = kPV_RGBA(r: 231, g: 231, b: 231, a: 1)
    
    // 上下间距
    @objc public var topBottomMargin:CGFloat        = 10
    // 左右间距
    @objc public var letfRigthMargin:CGFloat        = 10
    
    /// 自定义弹窗校准位置
    @objc public var popupCustomAlignment           = FWPopupCustomAlignment.center
    /// 弹窗EdgeInsets
    @objc public var popupViewEdgeInsets            = UIEdgeInsetsMake(0, 0, 0, 0)
    
    public override init() {
        super.init()
    }
}
