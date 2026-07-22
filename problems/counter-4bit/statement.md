# 4-bit Counter

Implement a synchronous 4-bit binary up-counter.

## Ports

| Name | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk`| input     | 1     | Clock |
| `rst`| input     | 1     | Synchronous, active-high reset |
| `q`  | output    | 4     | Count value |

## Behavior

- On the rising edge of `clk`, if `rst` is `1`, set `q` to `4'b0000`.
- On the rising edge of `clk`, if `rst` is `0`, set `q` to `q + 1` (wraps from `15` to `0`).
- `q` must update only on the rising edge of `clk` (synchronous reset and count).
