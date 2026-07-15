# Full Adder

Implement a 1-bit full adder.

## Ports

| Name  | Direction | Width | Description |
|-------|-----------|-------|-------------|
| `a`   | input     | 1     | First addend |
| `b`   | input     | 1     | Second addend |
| `cin` | input     | 1     | Carry in |
| `sum` | output    | 1     | Sum bit |
| `cout`| output    | 1     | Carry out |

## Behavior

Compute `{cout, sum} = a + b + cin` (unsigned 1-bit addition with carry).

Truth table expectations:

- `sum  = a XOR b XOR cin`
- `cout = (a AND b) OR (a AND cin) OR (b AND cin)`
