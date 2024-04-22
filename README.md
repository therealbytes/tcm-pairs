This implementation imposes a cap on the total volume of tokens that can be swapped within a 24-hour period. Future versions may introduce separate caps for each swap direction, as well as caps on the net volume swapped in one given direction.

| src/Pair.sol:Pair contract |                 |       |        |       |         |
|----------------------------|-----------------|-------|--------|-------|---------|
| Deployment Cost            | Deployment Size |       |        |       |         |
| 386626                     | 1577            |       |        |       |         |
| Function Name              | min             | avg   | median | max   | # calls |
| deposit                    | 26299           | 36944 | 29885  | 54648 | 3       |
| depositLite                | 29826           | 42214 | 42214  | 54602 | 2       |
| swap                       | 25001           | 54699 | 52172  | 86218 | 6       |
| swapLite                   | 32397           | 68723 | 78371  | 85754 | 4       |


| src/VolumeLimitedPair.sol:VolumeLimitedPair contract |                 |       |        |        |         |
|------------------------------------------------------|-----------------|-------|--------|--------|---------|
| Deployment Cost                                      | Deployment Size |       |        |        |         |
| 752100                                               | 3113            |       |        |        |         |
| Function Name                                        | min             | avg   | median | max    | # calls |
| swap                                                 | 34783           | 96506 | 93631  | 135500 | 26      |
| swapLite                                             | 38260           | 95326 | 93121  | 134990 | 13      |
