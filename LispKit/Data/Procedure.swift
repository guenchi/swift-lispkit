//
//  Procedure.swift
//  LispKit
//
//  Created by Matthias Zenger on 21/01/2016.
//  Copyright © 2016 ObjectHub. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

///
/// Procedures encapsulate functions that can be applied to arguments. Procedures have an
/// identity, a name, and a definition in the form of property `kind`. There are four kinds
/// of procedure definitions:
///    1. Primitives: These are built-in procedures
///    2. Closures: These are user-defined procedures, e.g. via `lambda`
///    3. Continuations: These are continuations generated by `call-with-current-continuation`
///    4. Transformers: These are user-defined macro transformers defined via `syntax-rules`
///
public final class Procedure: Reference, CustomStringConvertible {
  
  /// There are four kinds of procedures:
  ///    1. Primitives: These are built-in procedures
  ///    2. Closures: These are user-defined procedures, e.g. via `lambda`
  ///    3. Continuations: These are continuations generated by `call-with-current-continuation`
  ///    4. Transformers: These are user-defined macro transformers defined via `syntax-rules`
  public enum Kind {
    case Primitive(String, Implementation, FormCompiler?)
    case Closure(String?, [Expr], Code)
    case Continuation(VirtualMachineState)
    case Transformer(SyntaxRules)
  }
  
  /// There are three different types of primitive implementations:
  ///    1. Evaluators: They map the arguments into code that the VM is supposed to execute
  ///    2. Applicators: They map the arguments to a continuation procedure and an argument list
  ///    3. Native implementations: They map the arguments into a result value
  public enum Implementation {
    case Eval((Arguments) throws -> Code)
    case Apply((Arguments) throws -> (Procedure, [Expr]))
    case Native0(() throws -> Expr)
    case Native1((Expr) throws -> Expr)
    case Native2((Expr, Expr) throws -> Expr)
    case Native3((Expr, Expr, Expr) throws -> Expr)
    case Native4((Expr, Expr, Expr, Expr) throws -> Expr)
    case Native0O((Expr?) throws -> Expr)
    case Native1O((Expr, Expr?) throws -> Expr)
    case Native2O((Expr, Expr, Expr?) throws -> Expr)
    case Native3O((Expr, Expr, Expr, Expr?) throws -> Expr)
    case Native0R((Arguments) throws -> Expr)
    case Native1R((Expr, Arguments) throws -> Expr)
    case Native2R((Expr, Expr, Arguments) throws -> Expr)
    case Native3R((Expr, Expr, Expr, Arguments) throws -> Expr)
  }
  
  /// Procedure kind
  public let kind: Kind
  
  /// Initializer for primitive evaluators
  public init(_ name: String,
              _ proc: (Arguments) throws -> Code,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Eval(proc), compiler)
  }
  
  /// Initializer for primitive evaluators
  public init(_ name: String,
              _ compiler: FormCompiler,
              in context: Context) {
    func indirect(args: Arguments) throws -> Code {
      let expr =
        Expr.Pair(.Sym(Symbol(context.symbols.intern(name), .System)), .List(args))
      return try Compiler.compile(context,
                                  expr: .Pair(expr, .Null),
                                  in: .System,
                                  optimize: false)
    }
    self.kind = .Primitive(name, .Eval(indirect), compiler)
  }
  
  /// Initializer for primitive applicators
  public init(_ name: String,
              _ proc: (Arguments) throws -> (Procedure, [Expr]),
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Apply(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: () throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native0(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native1(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native2(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr, Expr) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native3(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr, Expr, Expr) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native4(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr?) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native0O(proc), compiler)
  }

  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr?) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native1O(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr, Expr?) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native2O(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr, Expr, Expr?) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native3O(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Arguments) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native0R(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Arguments) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native1R(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr, Arguments) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native2R(proc), compiler)
  }
  
  /// Initializer for primitive procedures
  public init(_ name: String,
              _ proc: (Expr, Expr, Expr, Arguments) throws -> Expr,
              _ compiler: FormCompiler? = nil) {
    self.kind = .Primitive(name, .Native3R(proc), compiler)
  }
  
  /// Initializer for closures
  public init(_ name: String?, _ captured: [Expr], _ code: Code) {
    self.kind = .Closure(name, captured, code)
  }
  
  /// Initializer for closures
  public init(_ code: Code) {
    self.kind = .Closure(nil, [], code)
  }
  
  /// Initializer for continuations
  public init(_ vmState: VirtualMachineState) {
    self.kind = .Continuation(vmState)
  }
  
  /// Initializer for transformers
  public init(_ rules: SyntaxRules) {
    self.kind = .Transformer(rules)
  }
  
  /// Returns the name of this procedure. This method either returns the name of a primitive
  /// procedure or the identity as a hex string.
  public var name: String {
    switch self.kind {
      case .Primitive(let str, _, _):
        return str
      case .Closure(.Some(let str), _, _):
        return "\(str)@\(String(self.identity, radix: 16))"
      default:
        return String(self.identity, radix: 16)
    }
  }
  
  public func mark(tag: UInt8) {
    switch self.kind {
      case .Closure(_, let captures, let code):
        for capture in captures {
          capture.mark(tag)
        }
        code.mark(tag)
      default:
        break
    }
  }
  
  /// A textual description
  public var description: String {
    return "proc#" + self.name
  }
}

public typealias Arguments = ArraySlice<Expr>

public extension ArraySlice {
    
  public func optional(fst: Element, _ snd: Element) -> (Element, Element)? {
    switch self.count {
      case 0:
        return (fst, snd)
      case 1:
        return (self[self.startIndex], snd)
      case 2:
        return (self[self.startIndex], self[self.startIndex + 1])
      default:
        return nil
    }
  }
  
  public func optional(fst: Element,
                       _ snd: Element,
                       _ trd: Element) -> (Element, Element, Element)? {
    switch self.count {
      case 0:
        return (fst, snd, trd)
      case 1:
        return (self[self.startIndex], snd, trd)
      case 2:
        return (self[self.startIndex], self[self.startIndex + 1], trd)
      case 3:
        return (self[self.startIndex], self[self.startIndex + 1], self[self.startIndex + 2])
      default:
        return nil
    }
  }
}

///
/// A `FormCompiler` is a function that compiles an expression for a given compiler in a
/// given environment and tail position returning a boolean which indicates whether the
/// expression has resulted in a tail call.
///
public typealias FormCompiler = (Compiler, Expr, Env, Bool) throws -> Bool
