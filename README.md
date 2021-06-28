helm-upgrade-action
A GitHub Action for installing/upgrading a helm chart. We recommend using patriotsoftware/helm-upgradepaction@v1 to get the latest changes. If new features require breaking changes, we will release them to @v2. You can also use a full semantic version tag.

Example Usage
- uses: patriotsoftware/helm-upgrade-action@v1
Inputs
base-chart:
  This is any chart that you add any customizations onto. It looks for a local path.
namespace:
  Namespace to install the helm chart to within kubernetes.
values-file:
  Can accept multiple comma separated values, needs the path included in the file name.
inline-values:
  Typically will being with -- (needs included in the values). These will not be prefaced with anything.
additional-values:
  Values to be prefaced with --set.
release-name:
  Name that will be used for the helm install, will also be used for a status check.

Testing the action locally
Running locally will require a local cluster, such as kind which is used in the test workflow.
