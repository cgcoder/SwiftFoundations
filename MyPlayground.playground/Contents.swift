import Cocoa

import Foundation

struct Student {
  var name: String = "Raj"

  func greet() -> Void {
    print("Hello \(self.name)")
  }

  func getGreeter() -> () -> Void {
    return self.greet
  }
}
print("Hello")
let s: Student = Student()
s.getGreeter()()
