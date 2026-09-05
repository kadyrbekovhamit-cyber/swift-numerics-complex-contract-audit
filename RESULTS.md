# Recorded results

Environment:

- Apple Swift 6.1.2
- arm64 macOS
- Swift Numerics `899af71c0256d0ad181e3b7eb3453c1065d928a5`
- release build

## Fixed reciprocal example

```text
simple reciprocal counterexample
  numerator=(1e+300, 0.0)
  denominator=(1e+300, 1e+200)
  reciprocal=(9.999999999999999e-301, 0.0)
  quotient=(0.9999999999999999, -1e-100)
  product=(0.9999999999999999, 0.0)
  equal=false
```

## Deterministic stress scan

```text
iterations=2000000
eligible finite cases=1850381
mismatches=129170
mismatch rate among eligible cases=6.98072%
```

Each generated real and imaginary input component is a finite, normal
binary64 number. Cases whose quotient or reciprocal product is non-finite are
excluded from the eligible count. The pseudorandom seed is fixed in source.

The exponent field is deliberately sampled approximately uniformly. This is a
stress distribution designed to exercise scale separation; the percentage is
not a real-world prevalence estimate.

## Integer-power examples

```text
base=(-1.0, 0.0) n=31
  observed=(-1.0, 7.349118756157295e-15)
  expected=(-1.0, 0.0)
  normError=7.349118756157295e-15

base=(-1.0, 0.0) n=4503599627370495
  observed=(-0.16016429413387553, 0.9870903701711397)
  expected=(-1.0, 0.0)
  normError=1.296021377806805

base=(-1.0, 0.0) n=9007199254740991
  observed=(0.38081245093112503, 0.9246523007140736)
  expected=(-1.0, 0.0)
  normError=1.661813738618817
```

All three integer exponents are exactly representable as `Double`.
