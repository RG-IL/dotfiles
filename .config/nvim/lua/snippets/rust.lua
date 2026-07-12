return {
  main = "fn main() {\n\t$1\n}",
  fn = "fn ${1:name}(${2}) ${3:-> ${4:()} }{\n\t$0\n}",
  ["for"] = "for ${1:i} in ${2:0..10} {\n\t$0\n}",
  println = [[println!("${1}");]],
  impl = "impl ${1:Type} {\n\t$0\n}",
  match = "match ${1:expr} {\n\t${2:Pattern} => ${3},\n\t_ => ${4},\n}",
  let = "let ${1:var} = ${2};",
}
