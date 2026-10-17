# claude-plugins

Claude Code plugins for working with RealTree products.

## Install

Add this repository as a plugin marketplace once, then install the plugins you want:

```
/plugin marketplace add realtree-systems/claude-plugins
/plugin install jyro@realtree-systems
```

## Plugins

| Plugin | What it does | Licence |
| --- | --- | --- |
| [jyro](plugins/jyro) | Read, write and debug Jyro scripts, with compiler feedback on every edit when the `jyro` CLI is installed | CC BY-NC-SA 4.0 |

## Layout

```
.claude-plugin/marketplace.json   the marketplace: lists every plugin
plugins/<name>/                   one plugin each; this is what users install
tools/<name>/                     build scripts for a plugin, not installed
tests/<name>/                     tests for a plugin, not installed
```

Check the manifests before publishing:

```
claude plugin validate . --strict
claude plugin validate plugins/jyro --strict
```

## Licence

Everything in this repository is under the [MIT licence](LICENSE) unless a plugin's directory holds its own licence file, which then applies to that plugin.
