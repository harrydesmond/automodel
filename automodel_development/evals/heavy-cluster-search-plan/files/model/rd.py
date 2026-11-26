"""Method-of-lines solver for u_t = d/dx(D(u) u_x) + f(u). Reaction terms are a list of (name, coefficient)."""
import numpy as np

def solve(params, f_terms, x, t):
    ...  # returns u(x, t) on the measurement grid
