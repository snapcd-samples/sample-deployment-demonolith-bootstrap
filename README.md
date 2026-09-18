# sample-deployment-demonolith-bootstrap

Hands the monolith in [`sample-deployment-demonolith`](https://github.com/snapcd-samples/sample-deployment-demonolith) to Snap CD as a single module, so that a manual job can run [demonolith](https://github.com/schrieksoft/demonolith) against it: prove a split before merging it, then migrate the state after.

The monolith's own scripts split it by hand, in one shell session, with its inputs deliberately spread across four channels. This root collapses those into what a Snap CD module offers: every variable becomes a module parameter, and the state moves from the sample's MinIO store into Snap CD's own.

## Use it

```bash
tofu init
tofu apply
```

Every variable has a default matching the pre-configured `snapcd-selfhosted-deployment-docker`; `terraform.tfvars` is gitignored and holds local overrides. Apply the `monolith` module from the dashboard once this root has run.

`branch_name` selects the branch Snap CD deploys. A prove job runs a ref of its own without changing it.
