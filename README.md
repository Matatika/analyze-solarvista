# analyze-solarvista

Meltano project [file bundle](https://meltano.com/docs/command-line-interface.html#file-bundle) of Matatika datasets for Solarvista

Files:
- [`analyze/datasets`](./bundle/analyze/datasets) (directory)

Add plugin to `discovery.yml`:
```yaml
files:
- name: analyze-solarvista
  namespace: tap_solarvista
  update:
    analyze/datasets: true
  repo: https://github.com/Matatika/analyze-solarvista
  pip_url: git+https://github.com/Matatika/analyze-solarvista.git
```

Add plugin to your Meltano project:
```bash
# Add only the file bundle
meltano add files analyze-solarvista

# Add the file bundle as a related plugin through adding the Solarvista extractor
meltano add extractor --include-related tap-solarvista
```
