class TestRunner {

  ; Runs test classes with options
  ; tests := new TestRunner(options, class1, class2, ...)
  ; tests.run()

  __New(options, classes*) {
    this.options := options
    this.classes := classes
  }

  Run() {
    for _, cls in this.classes {
      new cls(this.options)
    }
  }
}
