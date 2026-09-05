# Swift Numerics complex contract audit

Three reproducible checks against Swift Numerics commit
`899af71c0256d0ad181e3b7eb3453c1065d928a5`:

1. `Complex.reciprocal` can be non-`nil` even though replacing direct division
   with multiplication by that reciprocal changes the result.
2. `Complex.pow(_: Int)` can accumulate large phase error because the current
   implementation evaluates integer powers through `exp(n * log(z))`.
3. The overflow-avoiding `Complex.cosh` and `Complex.sinh` paths apply the
   sign of a large negative real component to the wrong output components;
   the error propagates to `Complex.cos` and `Complex.sin`.

This is an independent engineering audit. It does not claim a security issue
or affiliation with Apple or the Swift Numerics maintainers.

## Quick reproduction

Requirements: macOS and Swift 5.9 or newer.

```bash
swift run -c release
```

The program first prints fixed, exactly understood examples and then runs a
deterministic two-million-case stress scan of the documented reciprocal/
division equivalence.

## Smallest reciprocal counterexample

```swift
import ComplexModule

typealias C = Complex<Double>
let a = C(1e300, 0)
let b = C(1e300, 1e200)

print(a / b)
print(a * b.reciprocal!)
```

Observed on Apple Swift 6.1.2, arm64 macOS:

```text
a / b          = (0.9999999999999999, -1e-100)
a * reciprocal = (0.9999999999999999, 0.0)
```

The reciprocal's imaginary component underflows to zero. Direct division's
rescaled path preserves its effect after multiplication by the large
numerator.

## Integer-power examples

```text
pow(-1 + 0i, 31)
observed = (-1.0, 7.349118756157295e-15)
expected = (-1.0, 0.0)
norm error = 33.0975 * Double.ulpOfOne

pow(-1 + 0i, 4_503_599_627_370_495)
observed = (-0.16016429413387553, 0.9870903701711397)
expected = (-1.0, 0.0)
norm error = 1.296021377806805
```

The larger exponent is still below `2^53`, so it is exactly representable as
`Double`. This example is therefore not explained by the source TODO about
rounding the integer during conversion to `RealType`.

## Large-negative hyperbolic sign counterexample

```swift
import ComplexModule

typealias C = Complex<Double>
print(C.cosh(C(-40, 0.5)))
print(C.sinh(C(-40, 0.5)))
```

Observed:

```text
cosh(-40 + 0.5i) = ( 1.032850027510405e+17,  5.642485416641618e+16)
sinh(-40 + 0.5i) = (-1.032850027510405e+17, -5.642485416641618e+16)
```

Expected from the defining identities, conjugation symmetry, and an
independent 80-decimal-digit `mpmath` evaluation:

```text
cosh(-40 + 0.5i) = ( 1.032850027510405e+17, -5.642485416641618e+16)
sinh(-40 + 0.5i) = (-1.032850027510405e+17,  5.642485416641618e+16)
```

This is a component-sign and quadrant error, not an ULP-level disagreement.
For `Double`, the affected fast path starts at `abs(real) ≈ 36.04`.

## Interpretation boundary

- The reciprocal result directly contradicts the public documentation's
  statement that, whenever the reciprocal is non-`nil`, the direct division
  and reciprocal-multiplication computations are always equivalent.
- The integer-power result is an accuracy and algorithm-selection finding.
  No universal ULP bound is claimed for `Complex.pow`.
- The hyperbolic result violates exact sign symmetries and is independently
  confirmed at high precision. The current near-overflow tests contain the
  same incorrect negative-input sign expectations.
- The stress scan deliberately samples binary64 exponent fields uniformly.
  Its mismatch rate characterizes that adversarial distribution, not ordinary
  application workloads.

See [FINDINGS.md](FINDINGS.md) and [RESULTS.md](RESULTS.md) for the complete
evidence boundary and recorded output.

## Upstream references

- [Filed upstream as Swift Numerics issue #346](https://github.com/apple/swift-numerics/issues/346)
- [Hyperbolic component-sign failure filed as issue #347](https://github.com/apple/swift-numerics/issues/347)
- [`Complex.reciprocal` documentation and implementation](https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Sources/ComplexModule/Complex%2BAlgebraicField.swift#L144-L164)
- [`Complex.pow(_: Int)` implementation](https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Sources/ComplexModule/Complex%2BElementaryFunctions.swift#L429-L441)
- [`ElementaryFunctions.pow(_: Int)` documentation](https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Sources/RealModule/ElementaryFunctions.swift#L207-L212)
- [`Complex.cosh` and `Complex.sinh` implementation](https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Sources/ComplexModule/Complex%2BElementaryFunctions.swift#L141-L183)
- [Existing large-negative-input tests](https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Tests/ComplexTests/ElementaryFunctionTests.swift#L175-L215)

## License

MIT. Swift Numerics itself is licensed separately by its authors.
