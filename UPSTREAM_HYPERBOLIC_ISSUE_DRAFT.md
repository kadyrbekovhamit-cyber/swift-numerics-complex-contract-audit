## Summary

Published as [Swift Numerics issue #347](https://github.com/apple/swift-numerics/issues/347).

The overflow-avoiding fast paths for `Complex.cosh` and `Complex.sinh` return
the wrong sign for one component when the real part is sufficiently large and
negative. Because `Complex.cos` and `Complex.sin` are defined in terms of these
functions, the error propagates to them for sufficiently large positive
imaginary parts.

This is a sign/quadrant error rather than an accuracy-at-the-last-bit issue.

## Reproducer

Tested against `main` at `899af71c0256d0ad181e3b7eb3453c1065d928a5`:

```swift
import ComplexModule

typealias C = Complex<Double>

print(C.cosh(C(-40, 0.5)))
print(C.sinh(C(-40, 0.5)))
print(C.cos(C(0.5, 40)))
print(C.sin(C(0.5, 40)))
```

Observed:

```text
cosh(-40 + 0.5i) = ( 1.032850027510405e+17,  5.642485416641618e+16)
sinh(-40 + 0.5i) = (-1.032850027510405e+17, -5.642485416641618e+16)
cos( 0.5 + 40i)  = ( 1.032850027510405e+17,  5.642485416641618e+16)
sin( 0.5 + 40i)  = (-5.642485416641618e+16,  1.032850027510405e+17)
```

Expected (rounded here to the same displayed precision):

```text
cosh(-40 + 0.5i) = ( 1.032850027510405e+17, -5.642485416641618e+16)
sinh(-40 + 0.5i) = (-1.032850027510405e+17,  5.642485416641618e+16)
cos( 0.5 + 40i)  = ( 1.032850027510405e+17, -5.642485416641618e+16)
sin( 0.5 + 40i)  = ( 5.642485416641618e+16,  1.032850027510405e+17)
```

## Independent checks

The defining identities are:

```text
cosh(x + iy) = cosh(x) cos(y) + i sinh(x) sin(y)
sinh(x + iy) = sinh(x) cos(y) + i cosh(x) sin(y)
```

Since `cosh` is even and `sinh` is odd in the real argument, these also give
the exact symmetries:

```text
cosh(-x + iy) = conjugate(cosh(x + iy))
sinh(-x + iy) = -conjugate(sinh(x + iy))
```

The observed values violate both symmetries. An independent 80-decimal-digit
`mpmath` evaluation gives:

```text
cosh(-40 + 0.5i)
= 103285002751040493.884940309205... - 56424854166416174.631995251979...i

sinh(-40 + 0.5i)
= -103285002751040493.884940309205... + 56424854166416174.631995251979...i
```

## Cause

In the large-`abs(x)` branches, both real hyperbolic factors are approximated
using `exp(abs(x))/2`. For negative `x`, only the `sinh(x)` factor is odd:

- `cosh`: the sign of `x` belongs only on the imaginary component.
- `sinh`: the sign of `x` belongs only on the real component.

The current `cosh` branch applies no sign correction, while the current `sinh`
branch applies the sign to the whole complex value.

For `Double`, this branch starts at approximately
`abs(x) >= -log(Double.ulpOfOne)`, or `36.04`.

The current near-overflow tests use the same incorrect sign expectations for
negative `x`: `cosh(-x + i*pi/4)` expects a positive imaginary component, and
`sinh(-x + i*pi/4)` expects a negative imaginary component.

## Possible fix direction

In the scaled branches, let `sx` be `+1` or `-1` according to the sign of the
real component. Then form the phase factors as:

```text
cosh: (cos(y), sx * sin(y))
sinh: (sx * cos(y), sin(y))
```

and update the negative-real test expectations. The existing two-step scaling
can remain unchanged.

## Source locations

- Implementation: <https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Sources/ComplexModule/Complex%2BElementaryFunctions.swift#L141-L183>
- Existing tests: <https://github.com/apple/swift-numerics/blob/899af71c0256d0ad181e3b7eb3453c1065d928a5/Tests/ComplexTests/ElementaryFunctionTests.swift#L175-L215>

Executable reproducer and recorded output:
<https://github.com/kadyrbekovhamit-cyber/swift-numerics-complex-contract-audit>

I did not find an existing issue or pull request describing this negative-real
component-sign failure using searches for `Complex cosh negative`,
`Complex sinh negative`, and `hyperbolic imaginary sign`.
