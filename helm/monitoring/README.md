# Monitoring Helm Chart

This chart deploys Prometheus and Grafana for cluster-wide monitoring using the official community Helm charts as dependencies.

## Features
- Prometheus with node-exporter for node metrics
- Grafana with admin/admin123 (change in values.yaml)
- Both services are exposed as ClusterIP by default

## Accessing Grafana
- Port-forward to access Grafana UI:
  ```sh
  kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
  ```
  Then open http://localhost:3000 (user: admin, pass: admin123)

## Customization
- Change `values.yaml` to adjust service type, credentials, or enable persistence. 