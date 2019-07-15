//
//  ExpOp.swift
//  mat4ipad
//
//  Created by ingun on 03/06/2019.
//  Copyright © 2019 ingun37. All rights reserved.
//

import Foundation
func replaced(e:Exp, uid:String, to:Exp)-> Exp {
    var o = e
    o.kids = o.kids.map({replaced(e: $0, uid: uid, to: to)})
    o.kids = o.kids.map({$0.uid == uid ? to : $0})
    if let o = o as? AssociativeExp {
        return o.associated()
    }
    return o
}
func removed(e:Exp, uid:String)-> Exp {
    var o = e
    o.kids.removeAll(where: {$0.uid == uid})
    o.kids = o.kids.map({removed(e: $0, uid: uid)})
    o.kids.removeAll(where: {$0.needRemove()})
    o.kids = o.kids.map({ e in
        if let successor = e.needRetire() {
            return e.kids[successor]
        } else {
            return e
        }
    })
    if let o = o as? AssociativeExp {
        return o.associated()
    }
    return o
}
func if2<T:Exp>(_ a:Exp, _ b:Exp, _ c:(T, T) throws ->Exp) throws ->Exp? {
    if let a = a as? T, let b = b as? T {
        return try c(a, b)
    }
    return nil
}
func if1<T:Exp>(_ a:Exp, _ b:Exp, _ c:(T, Exp) throws ->Exp?) throws ->Exp? {
    if let a = a as? T {
        return try c(a, b)
    } else if let b = b as? T {
        return try c(b, a)
    }
    return nil
}
func add(_ a:Exp, _ b:Exp) throws -> Exp {
    return try if2(a, b, { (a:Mat, b:Mat) -> Exp in
        guard a.cols == b.cols && a.rows == b.rows else {
            throw evalErr.matrixSizeNotMatch(a, b)
        }
        let new2d = try (0..<a.rows).map({i in
            try zip(a.row(i), b.row(i)).map({ try add($0, $1) })
        })
        return Mat(new2d)
    }) ?? if2(a, b, { (a:NumExp, b:NumExp) -> Exp in
        return a+b
    }) ?? if1(a, b, { (a:NumExp, b) -> Exp? in
        return a.isZero ? b : nil
    }) ?? Add([a, b])
}
func mul(_ a:Exp, _ b:Exp) throws ->Exp {//never call eval in here
    return try if2(a, b, { (a:Mat, b:Mat) -> Exp in
        guard a.cols == b.rows else {
            throw evalErr.matrixSizeNotMatch(a, b)
        }
        let new2d = try (0..<a.rows).map({i in
            try (0..<b.cols).map({j-> Exp in
                let products = try zip(a.row(i), b.col(j)).map({try mul($0, $1)})
                return try products.dropFirst().reduce(products[0], {try add($0, $1)})
            })
        })
        return Mat(new2d)
    }) ?? if2(a, b, { (a:Unassigned, b:Unassigned) -> Exp in
        return Unassigned("\(a.letter)\(b.letter)")
    }) ?? if2(a, b, { (a:NumExp, b:NumExp) -> Exp in
        return a * b
    }) ?? if1(a, b, { (a:NumExp, b) -> Exp? in
        if a.isIdentity {
            return b
        }
        if let b = b as? Mat {
            let rows = try (0..<b.rows).map({try b.row($0).map({try mul($0, a)})})
            return Mat(rows)
        }
        return nil
    }) ?? Mul([a, b])
}
