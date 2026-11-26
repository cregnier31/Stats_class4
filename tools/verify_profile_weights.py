"""Compare legacy and optimized horizontal profile interpolation on synthetic data."""
import argparse
import logging
from pathlib import Path
from time import perf_counter

import numpy as np
from joblib import Parallel, delayed
from tep_class4.core.Interpolator import Interpolator
from tep_class4.core.Interp_kdtree import interp_KDtree


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--levels", type=int, default=20)
    parser.add_argument("--nx", type=int, default=360)
    parser.add_argument("--ny", type=int, default=180)
    parser.add_argument("--observations", type=int, default=1000)
    args = parser.parse_args()
    if Path("test.p").exists():
        raise SystemExit("Run in a directory without test.p (existing weight cache).")
    if min(args.levels, args.nx, args.ny, args.observations) < 1 or args.nx * args.ny < 4:
        parser.error("Positive sizes and at least four grid points required")
    log = logging.getLogger("verify")
    interp = Interpolator(log)
    tree = interp_KDtree(log)
    rng = np.random.default_rng(42)
    lon, lat = np.meshgrid(np.linspace(-179, 179, args.nx),
                           np.linspace(-80, 80, args.ny))
    x = rng.uniform(-178, 178, args.observations)
    y = rng.uniform(-79, 79, args.observations)
    n = args.levels
    k = 4
    field = rng.normal(size=(n, args.ny, args.nx))
    mask = rng.random(field.shape) > 0.1
    field[~mask] = np.nan

    start = perf_counter()
    pairs = Parallel(n_jobs=-1, backend="threading")(
        delayed(interp.compute_weight)(i, tree, lon, lat, x.copy(),
                                       y.copy(), k, mask[i])
        for i in range(n))
    old_w, old_i = map(np.asarray, zip(*pairs))
    old_weight_time = perf_counter() - start

    start = perf_counter()
    new_w, new_i = interp.compute_profile_weights(
        tree, lon, lat, x, y, k, mask, n)
    new_weight_time = perf_counter() - start
    np.testing.assert_array_equal(old_i, new_i)
    np.testing.assert_array_equal(old_w, new_w)

    def legacy_level(i):
        # Reproduce the former full-field copy in each level task.
        return interp.compute_3D_weight_origin(
            i, np.array(field), old_i, old_w, n, k)

    start = perf_counter()
    old = np.asarray(Parallel(n_jobs=-1, backend="threading")(
        delayed(legacy_level)(i) for i in range(n)))
    old_interp_time = perf_counter() - start
    start = perf_counter()
    shared_field = np.asarray(field)
    new = np.asarray(Parallel(n_jobs=-1, backend="threading")(
        delayed(interp.compute_3D_weight_origin)(
            i, shared_field, new_i, new_w, n, k) for i in range(n)))
    new_interp_time = perf_counter() - start
    np.testing.assert_array_equal(old, new)
    print("Indices, weights and horizontal interpolated values: EXACT PASS")
    print(f"Weights: legacy {old_weight_time:.3f}s, optimized {new_weight_time:.3f}s")
    print(f"Interpolation: legacy {old_interp_time:.3f}s, optimized {new_interp_time:.3f}s")
    print(f"Weight/index storage: legacy {old_w.nbytes + old_i.nbytes:,} bytes, "
          f"optimized {new_w[0].nbytes + new_i[0].nbytes:,} bytes (shared views)")


if __name__ == "__main__":
    main()
