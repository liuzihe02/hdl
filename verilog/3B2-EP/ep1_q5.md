# Question 5: Gray Code Counter Design

## Gray Code Sequence Analysis

The given Gray code sequence is:
```
State | D₁ D₂ D₃
------|----------
  1   | 0  0  0
  2   | 0  0  1
  3   | 0  1  1
  4   | 0  1  0
  5   | 1  1  0
  6   | 1  1  1
  7   | 1  0  1
  8   | 1  0  0
```

## State Transition Table

Current State → Next State:
```
Current (D₁D₂D₃) → Next (D₁D₂D₃)
000 → 001
001 → 011
011 → 010
010 → 110
110 → 111
111 → 101
101 → 100
100 → 000 (wraps back to state 1)
```

## Deriving D Flip-Flop Input Equations

For D flip-flops, the next state IS the D input. We need to find:
- $D_1(\text{next})$ as a function of $D_1, D_2, D_3$
- $D_2(\text{next})$ as a function of $D_1, D_2, D_3$
- $D_3(\text{next})$ as a function of $D_1, D_2, D_3$

Using K-maps or inspection:

$$D_1(\text{next}) = D_1\overline{D_2} + D_1\overline{D_3} + \overline{D_1}D_2D_3$$

$$D_2(\text{next}) = \overline{D_1}\,\overline{D_3} + D_1D_3 + D_2\overline{D_3}$$

$$D_3(\text{next}) = \overline{D_1}\,\overline{D_2} + D_2\overline{D_3}$$

---

Or alternatively, using prime notation ('):

$$D_1(\text{next}) = D_1D_2' + D_1D_3' + D_1'D_2D_3$$

$$D_2(\text{next}) = D_1'D_3' + D_1D_3 + D_2D_3'$$

$$D_3(\text{next}) = D_1'D_2' + D_2D_3'$$