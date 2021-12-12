This project is a work-in-progress, and subject to change.

Proof-of-concept for an 'Adversarial liquidity pool'. In this pool, both tokens A and B are traded for some other token "backing token" as token A is bought, the value of token B decreases, and vice-versa. This is made possible with a variation of the invariant product formula. 

In the classic invariant product formula, A\*X=K before and after every swap, where A is the amount of token A in the pool, and X is the amount of the backing token, and K is some constant changed by added/removed liquidity. 

In this pool, A\*(X+B)=K is preserved, where B is the amount of token B in its parallel pool, also backed by token X. As a result of this relationship, higher values of B decrease the 'weight' of A relative to X, decreasing its value.

For example, let the token A liquidity pool have 1000 A and 0 X while the token B liquidity pool has 1000 B and 0 X. If user C buys half of the A, the A pool now has 500 A and 1000X. If the user now buys half of pool B, pool B will have 500B and 500X. 