//
//  ExpTreeView.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath
import RxSwift
import RxCocoa

protocol ExpViewable:UIView {
    var exp:Exp {get}
}
protocol ExpViewableDelegate {
    func onTap(view:ExpViewable)
    func changeto(uid:String, to: Exp)
}


class ExpView: UIView, ExpViewable {
    
    var del:ExpViewableDelegate?
    @IBOutlet weak var stack: UIStackView!
    var directSubExpViews:[ExpView] {
        return stack.arrangedSubviews.compactMap({$0 as? ExpView})
    }
    var allSubExpViews:[ExpView] {
        let directSubviews = directSubExpViews
        return directSubviews + directSubviews.map({$0.allSubExpViews}).flatMap({$0})
    }
    @IBOutlet weak var latexWrap: UIView!
    @IBOutlet weak var latexView: LatexView!
    
    @IBOutlet weak var matrixView: MatrixView!
    
    let disposeBag = DisposeBag()

    @IBAction func ontap(_ sender: Any) {
        del?.onTap(view: self)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
//    private var dragStartPosition:CGPoint = CGPoint.zero
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4;
        
        latexWrap.layer.cornerRadius = 4;
        latexWrap.layer.shadowColor = UIColor.black.cgColor
        latexWrap.layer.shadowOpacity = 0.5
        latexWrap.layer.shadowOffset = CGSize(width: 1, height: 1)
        latexWrap.layer.shadowRadius = 1
//
//        dragPan.rx.event.subscribe(onNext: {[unowned self] (rec) in
//            self.matrixResizePreviewBox.isHidden = false
//            let handle = self.dragHandle!
//            let matrixFrame = self.matrixView.frame
//            if rec.state == .began {
//                self.dragStartPosition = handle.frame.origin
//                self.previewWidthEqual.isActive = false
//                self.previewHeightEqual.isActive = false
//                self.previewWidth.isActive = true
//                self.previewHeight.isActive = true
//                self.matrixWidth.isActive = true
//                self.matrixWidth.constant = matrixFrame.width
//                self.matrixHeight.isActive = true
//                self.matrixHeight.constant = matrixFrame.height
//            }
//            let tran = rec.translation(in: nil)
//            self.previewWidth.constant = tran.x + matrixFrame.width
//            self.previewHeight.constant = tran.y + matrixFrame.height
//        }).disposed(by: self.disposeBag)
//
//        dragPan.rx.event.map({[unowned self] rec-> (Int, Int, UIGestureRecognizer.State) in
//            let matrixFrame = self.matrixView.frame
//            let cellHeight = Int(matrixFrame.height) / self.matrixView.mat.rows
//            let cellWidth = Int(matrixFrame.width) / self.matrixView.mat.cols
////            print("a: \(matrixFrame)")
//            let tran:CGPoint = rec.translation(in: nil)
//
//            return (Int(matrixFrame.height + tran.y) / cellHeight, Int(matrixFrame.width + tran.x) / cellWidth, rec.state)
//        }).distinctUntilChanged({ (l:(Int, Int, UIGestureRecognizer.State), r:(Int, Int, UIGestureRecognizer.State))-> Bool in
//            return l.0 == r.0 && l.1 == r.1 && l.2 == r.2
//        }).subscribe(onNext: { [unowned self] (newSz) in
//            let (newRow, newCol, state) = newSz
//            let oldrow = self.matrixView.mat.rows
//            let oldcol = self.matrixView.mat.cols
//            self.previewResizedMatrix(newRow: newRow, newCol: newCol)
//            if state == .ended {
//                self.del?.expandBy(mat: self.matrixView.mat, row: newRow - oldrow, col: newCol - oldcol)
//            }
//            if state == .began {
//                self.matrixView.layer.borderWidth = 0
//            }
//        }).disposed(by: disposeBag)
//
//        matrixResizePreviewBox.isHidden = true
//        matrixView.layer.borderColor = dragHandle.backgroundColor?.cgColor
//        matrixView.layer.borderWidth = 2
//        matrixResizePreviewBox.layer.borderColor = dragHandle.backgroundColor?.cgColor
//        matrixResizePreviewBox.layer.borderWidth = 2
    }
    func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
//        layer.masksToBounds = false
    }
    static func loadViewFromNib() -> ExpView {
        let bundle = Bundle(for: self)
        let nib = UINib(nibName: String(describing:self), bundle: bundle)
        return nib.instantiate(withOwner: nil, options: nil).first as! ExpView
    }
    
    var exp:Exp = Unassigned("z")
    func setExp(exp:Exp, del:ExpViewableDelegate) {
        self.exp = exp
        self.del = del
        latexView.set(exp.latex())
        if let exp = exp as? Mat {
            matrixView.isHidden = false
            stack.isHidden = true
            matrixView.set(exp, del:del)
        } else if exp.kids.isEmpty {
            matrixView.isHidden = true
            stack.isHidden = false
        } else {
            matrixView.isHidden = true
            stack.isHidden = false
            
            exp.kids.forEach({e in
                let v = ExpView.loadViewFromNib()
                v.setExp(exp: e, del:del)
                stack.addArrangedSubview(v)
            })
        }
    }
    
//    @IBOutlet weak var dragPan: UIPanGestureRecognizer!
    
    
//    @IBOutlet weak var matrixWrapper: UIView!
//    @IBOutlet weak var dragHandle: UIView!
//    @IBOutlet weak var matrixResizePreviewBox: UIView!
    
//    func previewResizedMatrix(newRow:Int, newCol:Int) {
//        let preview = matrixResizePreviewBox!
//        preview.isHidden = false
//        preview.subviews.forEach({v in
//            preview.willRemoveSubview(v)
//            v.removeFromSuperview()
//        })
//
//        let stackFrame = matrixView.frame
//
//        let cellw = stackFrame.size.width / CGFloat(matrixView.mat.cols)
//        let cellh = stackFrame.size.height / CGFloat(matrixView.mat.rows)
//        (0..<newRow+1).forEach({ ri in
//            let line = UIView(frame: CGRect(x: 0, y: CGFloat(ri)*cellh, width: CGFloat(newCol)*cellw, height: 1))
//            line.backgroundColor = UIColor.white
//            preview.addSubview(line)
//        })
//        (0..<newCol+1).forEach({ ci in
//            let line = UIView(frame: CGRect(x: CGFloat(ci)*cellw, y: 0, width: 1, height: CGFloat(newRow)*cellh))
//            line.backgroundColor = UIColor.white
//            preview.addSubview(line)
//        })
//    }
//    @IBOutlet weak var previewWidthEqual: NSLayoutConstraint!
//    @IBOutlet weak var previewHeightEqual: NSLayoutConstraint!
//    @IBOutlet weak var previewWidth: NSLayoutConstraint!
//    @IBOutlet weak var previewHeight: NSLayoutConstraint!
    @IBOutlet weak var matrixHeight: NSLayoutConstraint!
    @IBOutlet weak var matrixWidth: NSLayoutConstraint!
}

class ExpInitView:UIView {
    var contentView:ExpView?
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    func set(exp:Exp, del:ExpViewableDelegate)-> ExpView {
        if let v = contentView {
            willRemoveSubview(v)
        }
        contentView?.removeFromSuperview()
        
        let eview = ExpView.loadViewFromNib()
        
        eview.frame = bounds
        addSubview(eview)
        
        eview.layoutMarginsGuide.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
        eview.layoutMarginsGuide.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor).isActive = true
        eview.layoutMarginsGuide.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor).isActive = true
        eview.layoutMarginsGuide.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor).isActive = true
        
        contentView = eview
        
        
        eview.setExp(exp: exp, del: del)
        return eview
    }
}
