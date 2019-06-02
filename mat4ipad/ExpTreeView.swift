//
//  ExpTreeView.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import UIKit
import iosMath

protocol ExpTreeDelegate {
    func onTap(exp:Exp)
    func expandBy(mat:Mat, row:Int, col:Int)
    func changeMatrixElement(mat:Mat, row:Int, col:Int, txt:String)
}
import RxSwift
import RxCocoa

class ExpTreeView: UIView, MatCellDelegate {
    @IBOutlet weak var stackWidth: NSLayoutConstraint!
    
    @IBOutlet weak var stackHeight: NSLayoutConstraint!
    func onMatrixElementChange(_ i: Int, _ j: Int, to: String) {
        guard let mat = exp as? Mat else {return}
        print("\(i),\(j) to \(to)")
        del?.changeMatrixElement(mat: mat, row: i, col: j, txt: to)
    }
    
    var del:ExpTreeDelegate?
    @IBOutlet weak var outstack: UIStackView!
    @IBOutlet weak var stack: UIStackView!
    @IBOutlet weak var latexWrap: LatexView!
    
    @IBOutlet weak var matWrap: UIView!
    @IBOutlet weak var matcollection: MatCollection!
    var contentView:UIView?
    let disposeBag = DisposeBag()

    @IBAction func ontap(_ sender: Any) {
        guard let exp = exp else {return}
        print("sending \(exp.uid)")
        del?.onTap(exp: exp)
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
        
        layer.cornerRadius = 8;
        
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.shadowRadius = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
//        layer.masksToBounds = false
    }
    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing:type(of: self)), bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }
    @IBOutlet weak var latexWrapHeight: NSLayoutConstraint!
    
    private var exp:Exp?
    func setExp(exp:Exp, del:ExpTreeDelegate) {
        if true {
            self.exp = exp
            self.del = del
            latexWrap.set(exp.latex())
            
            if let exp = exp as? Mat {
                matWrap.isHidden = false
                stack.isHidden = true
                matcollection.set(exp: exp)
                stackWidth.constant = CGFloat(exp.cols * 100)
                stackHeight.constant = CGFloat(exp.rows * 100)
                
                let items = Observable.just(
                    exp.kids
                )
                
                items.bind(to: matcollection.rx.items(cellIdentifier: "cell", cellType: MatCell.self), curriedArgument: { (row, element, cell) in
                    if let e = element as? Unassigned {
                        cell.lbl.text = e.letter
                    } else if let e = element as? IntExp {
                        cell.lbl.text = "\(e.i)"
                    }
                    cell.set(row/exp.cols, row%exp.cols, del: self)
                    cell.lbl.rx.text.orEmpty.throttle(.milliseconds(200), scheduler: MainScheduler.instance).distinctUntilChanged().observeOn(MainScheduler.instance).skip(1).subscribe(onNext: {txt in
                        print("txt : \(txt)")
                    }).disposed(by: self.disposeBag)
                }).disposed(by: disposeBag)
                
                matcollection.rx.itemSelected.subscribe(onNext: { (idx) in
                    guard let cell = self.matcollection.cellForItem(at: idx) as? MatCell else {return}
                    cell.lbl.becomeFirstResponder()
                }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: disposeBag)
                
                
            } else {
                matWrap.isHidden = true
                stack.isHidden = false
                exp.kids.forEach({e in
                    let v = ExpTreeView()
                    v.setExp(exp: e, del:del)
                    stack.addArrangedSubview(v)
                })
            }
        }
    }
    @IBAction func increaseCol(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 0, col: 1)
    }
    @IBAction func decreaseCol(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 0, col: -1)
    }
    @IBAction func increaseRow(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: 1, col: 0)
    }
    @IBAction func decreaseRow(_ sender: Any) {
        guard let mat = exp as? Mat else {return}
        del?.expandBy(mat: mat, row: -1, col: 0)
    }
    
}

extension Range where Bound == Double {
    private func interp(_ n:Int, _ d:Int) -> Double {
        let a:Double = (upperBound*Double(n)/Double(d))
        let b:Double = (lowerBound*Double(d-n)/Double(d))
        return a + b
    }
    func block(_ numerator:Int, _ denominator:Int) -> Range<Double> {
        return interp(numerator, denominator)..<interp(numerator+1, denominator)
    }
}
class MatCollection:UICollectionView, UICollectionViewDelegateFlowLayout {
    @IBOutlet weak var initialWidthBiggerthan: NSLayoutConstraint!
    override func awakeFromNib() {
        super.awakeFromNib()
        register(UINib(nibName: "MatCell", bundle: Bundle(for: MatCell.self)), forCellWithReuseIdentifier: "cell")
        print("awake called")
        self.delegate = self
    }
    var rows = 1;
    var cols = 1;
    func set(exp:Mat) {
        print("set called")
        rows = exp.rows
        cols = exp.cols
        
    }
    func collectionView(_ cv: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let w = frame.size.width/CGFloat(cols)
        let h = frame.size.height/CGFloat(rows)
        
        return CGSize(width: w, height: h)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
protocol MatCellDelegate {
    func onMatrixElementChange(_ i:Int, _ j:Int, to:String)
}
class MatCell:UICollectionViewCell, UITextFieldDelegate {
    var del:MatCellDelegate?
    var i, j:Int!
    func set(_ i:Int, _ j:Int, del:MatCellDelegate) {
        self.i = i;
        self.j = j
        self.del = del
    }
    @IBOutlet weak var lbl: UITextField!
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        del?.onMatrixElementChange(i, j, to: textField.text ?? "")
        return true
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
