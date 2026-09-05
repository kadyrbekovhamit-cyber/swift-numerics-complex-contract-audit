# Swift Numerics candidate findings

Date: 2026-09-05  
Swift Numerics `main`: `899af71c0256d0ad181e3b7eb3453c1065d928a5`  
Local toolchain: Apple Swift 6.1.2, arm64 macOS

These are candidate findings, not yet upstream issue reports.

## 1. `Complex.pow(_: Int)` can return a value far from an exact integer power

The `ElementaryFunctions` API distinguishes real/complex exponentiation from
integer exponentiation. Its documentation says the integer overload is defined
in terms of repeated multiplication or division rather than `exp(n * log(x))`.

The current `Complex` implementation nevertheless evaluates:

```swift
return exp(log(z).multiplied(by: RealType(n)))
```

Reproducer:

```swift
import ComplexModule

typealias C = Complex<Double>
let z = C.pow(C(-1, 0), 4_503_599_627_370_495)
print(z)
```

Observed:

```text
(-0.16016429413387553, 0.9870903701711397)
```

Exact integer-power result:

```text
(-1.0, 0.0)
```

Norm error: `1.296021377806805`.

The exponent is below `2^53`, so it is exactly representable as `Double`.
This counterexample is therefore not explained by the source TODO about
rounding during `Int`-to-`RealType` conversion. The immediate mechanism is
phase-error amplification from the `log`/multiply/`exp` route.

A smaller case already exceeds the test suite's commonly used 16-ULP scale:

```text
Complex<Double>.pow(Complex(-1, 0), 31)
observed = (-1.0, 7.349118756157295e-15)
expected = (-1.0, 0.0)
norm error = 33.0975 * Double.ulpOfOne
```

## 2. `Complex.reciprocal` does not preserve division as documented

The public documentation says:

> If the reciprocal is non-nil, the two computations are always equivalent.

Simple reproducer:

```swift
import ComplexModule

typealias C = Complex<Double>
let a = C(1e300, 0)
let b = C(1e300, 1e200)
let reciprocal = b.reciprocal!

print(a / b)
print(a * reciprocal)
```

Observed:

```text
reciprocal     = (9.999999999999999e-301, 0.0)
a / b          = (0.9999999999999999, -1e-100)
a * reciprocal = (0.9999999999999999, 0.0)
```

The results are not equal. The reciprocal's small imaginary component
underflows to zero, while the rescaled direct-division path preserves its
effect after multiplication by the large numerator.

A deterministic stress scan over uniformly sampled binary64 exponent fields
found `129170` mismatches among `1850381` eligible finite cases (`6.98072%`).
This percentage characterizes that deliberately extreme exponent-distribution
stress test; it is not an estimate of frequency in ordinary applications.

## Existing-issue search

On 2026-09-05, repository issue searches for `reciprocal`,
`reciprocal equivalent`, and `"repeated multiplication"` returned no matching
issues. A broader `Complex pow` search returned older issues about zero edge
cases and real floating-point exponents, not these findings.

## Upstream sources

- Integer-power API contract: <https://github.com/apple/swift-numerics/blob/main/Sources/RealModule/ElementaryFunctions.swift#L195-L212>
- Current `Complex.pow` implementation: <https://github.com/apple/swift-numerics/blob/main/Sources/ComplexModule/Complex%2BElementaryFunctions.swift#L429-L441>
- `Complex.reciprocal` guarantee and implementation: <https://github.com/apple/swift-numerics/blob/main/Sources/ComplexModule/Complex%2BAlgebraicField.swift#L144-L164>
