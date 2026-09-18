# How to run

```
tofu init
export TF_VAR_source_url="git@github.com:snapcd-samples/sample-deployment-demonolith-bootstrap.git"
export TF_VAR_source_revision="main"
tofu apply --var-file demono.root.tfvars
```

The demono.* files are written by the `demonolith migrate` pipeline.
