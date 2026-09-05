# Title

`Complex.reciprocal` can be non-nil when reciprocal multiplication differs from direct division

Published as [Swift Numerics issue #346](https://github.com/apple/swift-numerics/issues/346).

## Description

The documentation for `Complex.reciprocal` says that whenever the reciprocal
is non-`nil`, direct division and multiplication by the reciprocal are always
equivalent. A finite-input counterexample produces two different finite
results.

## Minimal reproduction

```swift
import ComplexModule

typealias C = Complex<Double>
let a = C(1e300, 0)
let b = C(1e300, 1e200)

print(b.reciprocal!)
print(a / b)
print(a * b.reciprocal!)
print(a / b == a * b.reciprocal!)
```

Observed with Swift Numerics commit
`899af71c0256d0ad181e3b7eb3453c1065d928a5`:

```text
(9.999999999999999e-301, 0.0)
(0.9999999999999999, -1e-100)
(0.9999999999999999, 0.0)
false
```

## Expected/documented result

Because `b.reciprocal` is non-`nil`, the documented equivalence implies that
the final comparison should be `true`.

## Cause

The mathematically nonzero imaginary component of `1 / b` is approximately
`-1e-400`, so it underflows to zero when the reciprocal is materialized as a
`Complex<Double>`. Multiplication by the large numerator cannot recover it.
The direct division path rescales the operation and preserves the final,
representable `-1e-100` imaginary component.

## Environment

- Apple Swift 6.1.2
- arm64 macOS
- Swift Numerics `899af71c0256d0ad181e3b7eb3453c1065d928a5`
- release build

## Broader check

A deterministic two-million-case stress scan found 129,170 mismatches among
1,850,381 eligible finite-result cases. Every generated input component was a
finite, normal `Double`. The exponent fields were sampled approximately
uniformly to exercise scale separation, so the 6.98072% rate describes that
adversarial distribution and is not a real-world prevalence estimate.

Reproducer and complete recorded output:
https://github.com/kadyrbekovhamit-cyber/swift-numerics-complex-contract-audit

Would you prefer to narrow the documented guarantee, or should the API use a
different condition before returning a non-`nil` reciprocal?
