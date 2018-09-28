# Synchronized folder

This folder is synchronized with `/home/vagrant/synced` in your master node.

You can put manifests or anything in this folder and then apply them from within your master with something like this:

```shell
vagrant ssh master # I would just keep this session open in a separate terminal
cd synced
kubectl create -f my_manifest.yml
```
