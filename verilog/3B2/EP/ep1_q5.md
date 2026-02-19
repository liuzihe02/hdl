# Question 5: Gray Code Counter Design

## Gray Code Sequence Analysis

A Gray code is a binary encoding where **consecutive numbers differ by exactly 1 bit** (only one bit can flip). This contrasts with standard binary where multiple bits can flip at once (e.g., 3→4 is `011→100`, all 3 bits change).

**Standard binary vs Gray code:**

| Decimal | Binary | Gray |
|---------|--------|------|
| 0 | 000 | 000 |
| 1 | 001 | 001 |
| 2 | 010 | 011 |
| 3 | 011 | 010 |
| 4 | 100 | 110 |
| 5 | 101 | 111 |
| 6 | 110 | 101 |
| 7 | 111 | 100 |

## Convertig Between Binary and Gray

**Binary → Gray:** XOR each bit with the bit to its left.

$$G_i = B_i \oplus B_{i-1}$$

The MSB stays the same: $G_{n-1} = B_{n-1}$. You can think of this as taking the "derivative"

**Gray → Binary:** Propagate XORs from MSB downward.

$$B_i = B_{i+1} \oplus G_i$$

## Gray Code Flip Rule

**Flip gray code bit at position = number of trailing 1s in the current binary form**

| Step | n (binary) | Trailing 1s in n | Bit flipped | Gray code |
|------|-----------|-----------------|-------------|-----------|
| 0→1 | `000` | 0 | bit 0 | `000→001` |
| 1→2 | `001` | 1 | bit 1 | `001→011` |
| 2→3 | `010` | 0 | bit 0 | `011→010` |
| 3→4 | `011` | 2 | bit 2 | `010→110` |
| 4→5 | `100` | 0 | bit 0 | `110→111` |
| 5→6 | `101` | 1 | bit 1 | `111→101` |
| 6→7 | `110` | 0 | bit 0 | `101→100` |

## State Transition Table

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