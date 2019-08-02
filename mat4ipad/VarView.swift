//
//  VarView.swift
//  mat4ipad
//
//  Created by ingun on 02/08/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit

class VarView: UIView, ExpViewable {
    var exp: Exp {
        return expView?.exp ?? Unassigned(lbl.text ?? "Var")
    }
    
    @IBOutlet weak var stack:UIStackView!
    @IBOutlet weak var lbl:UILabel!
    var name = ""
    var expView:ExpView? = nil
    static func loadViewFromNib() -> VarView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! VarView
    }
    
    @discardableResult
    func set(name:String, exp:Exp, del:ExpViewableDelegate)-> ExpView {
        lbl.text = name
        let eview = ExpView.loadViewFromNib()
        if let prev = expView {
            stack.removeArrangedSubview(prev)
            prev.removeFromSuperview()
        }
        expView = eview
        stack.addArrangedSubview(eview)
        eview.setExp(exp: exp, del: del)
        self.name = name
        return eview
    }
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

class VarInitView:UIView {
    var varview:VarView
    
    required init?(coder aDecoder: NSCoder) {
        varview = VarView.loadViewFromNib()
        super.init(coder: aDecoder)
        varview.frame = bounds
        addSubview(varview)
    }
}
