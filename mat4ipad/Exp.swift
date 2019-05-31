//
//  Exp.swift
//  mat4ipad
//
//  Created by ingun on 29/05/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
import UIKit

protocol item {
    
}
enum Err:Error {
    case stackisempty
    case unknownArith
}

class Exp: item {
    let uid: String = UUID().uuidString
    var kids:[Exp] = []
    func latex() -> String {
        return ""
    }
    func replace(uid:String, to:Exp) {
        for i in 0..<kids.count {
            if kids[i].uid == uid {
                kids[i] = to
            } else {
                kids[i].replace(uid: uid, to: to)
            }
        }
    }
    func remove(uid:String) {
        kids.forEach({$0.remove(uid: uid)})
        kids.removeAll(where: {$0.uid == uid})
        kids.removeAll(where: {kid in
            if kid is BG || kid is Buffer || kid is Mul {
                if kid.kids.isEmpty {
                    return true
                }
            }
            return false
        })
        for i in 0..<kids.count {
            if kids[i] is Mul && kids[i].kids.count == 1{
                kids[i] = kids[i].kids[0]
            }
        }
    }
}

class Mul: Exp {
    override func latex() -> String {
        return kids.map({"{\($0.latex())}"}).joined(separator: " * ")
    }
    init(_ operands:[Exp]) {
        super.init()
        kids = operands
    }
}
class Mat:Exp {
    let rows, cols:Int
    override func latex() -> String {
        let array2d = (0..<rows).map({r in kids[r*cols..<r*cols+cols]})
        
        let inner = array2d.map({ $0.map({"{\($0.latex())}"}).joined(separator: " & ") }).joined(separator: "\\\\\n")
        return "\\begin{pmatrix}\n" + inner + "\n\\end{pmatrix}"
    }
    init(r:Int, c:Int) {
        rows = r
        cols = c
        super.init()
        kids = Array(repeating: BG(Unassigned("A")), count: rows*cols)
    }
    init(_ arr2d:[[Exp]]) {
        rows = arr2d.count
        cols = arr2d[0].count
        super.init()
        kids = arr2d.flatMap({$0})
    }
}
class Unassigned:Exp {
    override func latex() -> String {
        return letter
    }
    
    var letter:String
    init(_ l:String) {
        letter = l
        super.init()
    }
}
class BG:Exp {
    override func latex() -> String {
        return "\\colorbox{\(color.hex)}{\(kids[0].latex())}"
    }
    var e:Exp {
        return kids[0]
    }
    let color:UIColor = UIColor(hue: CGFloat(Float.random(in: 0.0..<1.0)), saturation: CGFloat(Float.random(in: 0.25..<0.4)), brightness: CGFloat(Float.random(in: 0.7..<0.9)), alpha: 1)
    
    init(_ e:Exp) {
        super.init()
        kids = [e]
    }
}
class Buffer:Exp {
    override func latex() -> String {
        return kids[0].latex()
    }
    
    init(_ e:Exp) {
        super.init()
        kids = [e]
    }
    
    var e:Exp {
        return kids[0]
    }
}
extension UIColor {
    var hex: String {
        get {
            var r:CGFloat = 0
            var g:CGFloat = 0
            var b:CGFloat = 0
            var a:CGFloat = 0
            
            getRed(&r, green: &g, blue: &b, alpha: &a)
            
            let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0
            
            return NSString(format:"#%06x", rgb) as String
        }
    }
}
