import ComplexModule

typealias C = Complex<Double>

func describe(_ base: C, _ n: Int) {
  let observed = C.pow(base, n)
  let expected: C
  if base == C(-1, 0) {
    expected = C(n.isMultiple(of: 2) ? 1 : -1, 0)
  } else if base == C(0, 1) {
    switch n % 4 {
    case 0: expected = C(1, 0)
    case 1: expected = C(0, 1)
    case 2: expected = C(-1, 0)
    default: expected = C(0, -1)
    }
  } else {
    expected = C(0, 0)
  }
  let normError = (observed - expected).length
  print("base=(\(base.real), \(base.imaginary)) n=\(n)")
  print("  observed=(\(observed.real), \(observed.imaginary))")
  print("  expected=(\(expected.real), \(expected.imaginary))")
  print("  normError=\(normError)")
}

let exponents: [Int] = [
  2,
  3,
  17,
  31,
  63,
  127,
  1_001,
  1_000_001,
  1_000_000_001,
  1_000_000_000_001,
  1_000_000_000_000_001,
  4_503_599_627_370_495,
  9_007_199_254_740_991,
  9_007_199_254_740_993,
]

for n in exponents {
  describe(C(-1, 0), n)
}

for n in exponents {
  describe(C(0, 1), n)
}

struct SplitMix64 {
  var state: UInt64

  mutating func next() -> UInt64 {
    state &+= 0x9e3779b97f4a7c15
    var z = state
    z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
    z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
    return z ^ (z >> 31)
  }

  mutating func finiteDouble() -> Double {
    let bits = next()
    let sign = bits & (1 << 63)
    let exponent = ((bits >> 52) % 2046 + 1) << 52
    let significand = next() & ((1 << 52) - 1)
    return Double(bitPattern: sign | exponent | significand)
  }
}

func scanReciprocalEquivalence(iterations: Int) {
  var rng = SplitMix64(state: 0x123456789abcdef0)
  var eligible = 0
  var mismatches = 0
  for _ in 0..<iterations {
    let numerator = C(rng.finiteDouble(), rng.finiteDouble())
    let denominator = C(rng.finiteDouble(), rng.finiteDouble())
    guard let reciprocal = denominator.reciprocal else { continue }
    let quotient = numerator / denominator
    let product = numerator * reciprocal
    guard quotient.isFinite && product.isFinite else { continue }
    eligible += 1
    guard quotient != product else { continue }
    mismatches += 1
    if mismatches <= 5 {
      print("reciprocal mismatch \(mismatches)")
      print("  numerator=(\(numerator.real), \(numerator.imaginary))")
      print("  denominator=(\(denominator.real), \(denominator.imaginary))")
      print("  reciprocal=(\(reciprocal.real), \(reciprocal.imaginary))")
      print("  quotient=(\(quotient.real), \(quotient.imaginary))")
      print("  product=(\(product.real), \(product.imaginary))")
    }
  }
  print("reciprocal scan: iterations=\(iterations) eligible=\(eligible) mismatches=\(mismatches)")
}

func showSimpleReciprocalCounterexample() {
  let numerator = C(1e300, 0)
  let denominator = C(1e300, 1e200)
  guard let reciprocal = denominator.reciprocal else {
    print("simple reciprocal: unexpectedly nil")
    return
  }
  let quotient = numerator / denominator
  let product = numerator * reciprocal
  print("simple reciprocal counterexample")
  print("  numerator=(\(numerator.real), \(numerator.imaginary))")
  print("  denominator=(\(denominator.real), \(denominator.imaginary))")
  print("  reciprocal=(\(reciprocal.real), \(reciprocal.imaginary))")
  print("  quotient=(\(quotient.real), \(quotient.imaginary))")
  print("  product=(\(product.real), \(product.imaginary))")
  print("  equal=\(quotient == product)")
}

showSimpleReciprocalCounterexample()
scanReciprocalEquivalence(iterations: 2_000_000)
