# W12 diagnostics, plot and repair challenge infrastructure

This directory is an offline challenge format and audit entry. It has no
completed diagnostic gold set, image review, repair benchmark or code-agent
sandbox result. Challenge cases must be frozen before labels are exposed and
must keep reference labels outside runner input.

The planned families are `diagnostic`, `plot` and `repair`. Each case needs a
source hash, challenge description, expected check scope and an independent
reference label. `not_checkable`, `runtime_only`, invariant failure and model
failure remain separate statuses.
