factory method cp(n, p, cs) {
  method key { codepoint }
  method codepoint { n }
  method position { p }
  method category { cs }
}
factory method nm(l, n) {
  method key { name }
  method name { l } 
  method codepoint { n }
}