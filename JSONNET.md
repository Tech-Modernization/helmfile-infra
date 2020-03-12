# JSONNET

## Overview
SLO dashboards can be patterned after the implementation at dash-kubeapi.jsonnet.
It follows the RED method (Requests Rate, Errors, Duration) and is a data-driven "Infrastructure as Code" approach which creates alerts and dashboards to support SLO dashboard/alerts for the Kubernetes API via Prometheus and Grafana.

jsonnet is used to build our rules and dashboards files from jsonnet input files. 

For kubeapi
* spec-kubeapi.jsonnet: as much data-only specification as possible (thresholds, rules and dashboards formulas)
 * alerts-kubeapi.jsonnet: outputs Prometheus alerts
 * rules-kubeapi.jsonnet: outputs Prometheus recording rules
 * dash-kubeapi.jsonnet: outputs Grafana dashboards, using grafonnet-lib via our opinionated grafana.libsonnet

The resulting rules/alerts json can be converted to yaml and used directly to configure prometheus and grafana.

## SLO Target and Metrics Thresholds
Let's define a simple target:
* SLO: 99%, from the following:
* SLIs:
 * error ratio under 1%
 * latency under 200ms for 90th&nbsp;percentile of requests

Writing above spec as jsonnet

```
slo:: {
  target: 0.99,
  error_ratio_threshold: 0.01,
  latency_percentile: 90,
  latency_threshold: 200,
}
```

## SLI
The Kubernetes API exposes several metrics we can use as SLIs, using the Prometheus rate() function over a short period (here we choose 5min, this number should be a few times your scraping interval):
```
apiserver_request_count: counts all the requests by verb, code, resource, e.g. to get the total error ratio for the last 5min: 
```
sum(rate(apiserver_request_count{code=3D~"5.."}[5m])) / sum(rate(apiserver_request_count[5m])) 
```

* The formula above discards all metrics labels (for example, by http&nbsp;verb, code). If you want to keep some labels, you'd need to do something similar to the following: 
```
sum by (verb, code) (rate(apiserver_request_=
 count{code=3D~"5.."}[5m]))
 / ignoring (verb, code) group_left 
 sum (rate(apiserver_request_count[5m]))
```
	
* apiserver_request_latencies_bucket: latency histogram by verb. For example, to get the 90th latency quantile in milliseconds: (note that the le "less or equal" label is special, as it sets the histogram buckets intervals, see [Prometheus histograms and summaries][promql-histogram]): 
```
histogram_quantile (0.90,
 sum by (le, verb, instance)(
    rate(apiserver_request_latencies_bucket[5m])
  )
) / 1e3
```
	 
## Writing Prometheus rules to record the chosen SLIs
PromQL is a very powerful language, although as of October 2018, it doesn't yet support nested subqueries for ranges (see Prometheus issue 1227 for details), a feature we'll need to be able to compute time ratio for error ratio or latency outside their thresholds.
Also, as good practice, to lower query-time Prometheus resource usage, it is recommended to always add recording rules to precompute expressions such as sum(rate(...)) anyway.
As an example of how to do this, the following set of recording rules are built from our [bitnami-labs/kubernetes-grafana-dashboards] repository to capture the above time ratio:
Create a new kubernetes:job_verb_code_instance:apiserver_requests:rate5m metric to record requests rates: 
```
record: kubernetes:job_verb= _code_instance:apiserver_requests:rate5m
expr: | sum by(job, verb, code, instance) (rate(apiserver_request_count[5m]))
```

Using above metric, create a new kubernetes:job_verb_code_instance:apiserver_requests:ratio_rate5m for the requests ;ratios (over total): 
```
record: kubernetes:job_verb_code_instance:apiserver_requests:ratio=
	_rate5m
	expr: |
	  kubernetes:job_verb_code_instance:apiserver_requests:rate5m
	    / ignoring(verb, code) group_left()
	  sum by(job, instance) (
	    kubernetes:job_verb_code_instance:apiserver_requests:rate5m
	  )
```

Using above ratio metrics (for every http code&nbsp;and verb), create a new one to capture the error ratios: 
```
record: kub= ernetes:job:apiserver_request_errors:ratio_rate5m
expr: |
 sum by(job) (
   kubernetes:job_verb_code_instance:apiserver_requests:ratio_rate5m
      {code=3D~"5..",verb=3D~"GET|POST|DELETE|PATCH"}
  )
```

Using above error ratios (and other similarly created kubernetes::job:apiserver_latency:pctl90rate5m one for recorded 90th percentile latency over the past 5mins, not shown above for simplicity),finally create a boolean metric to record our SLO complaince: 
```
record: kubernetes::job:sl=
	o_kube_api_ok
	expr: |
	  kubernetes:job:apiserver_request_errors:ratio_rate5m < bool 0.01
	    *
	  kubernetes::job:apiserver_latency:pctl90rate5m < bool 200
```
	 
## Writing Prometheus alerting rules
The above kubernetes::job:slo_kube_api_ok final metric is very useful for dashboards and accounting for SLO compliance, but we should alert on which of above metrics is driving the SLO off, as shown the following Prometheus alert rules:
```
	Alert on high API error ratio: alert: KubeAPIErrorRatioHigh
	expr: |
	  sum by(instance) (
	    kubernetes:job_verb_code_instance:apiserver_requests:ratio_rate5m
	      {code=3D~"5..",verb=3D~"GET|POST|DELETE|PATCH"}
	  ) > 0.01
	for: 5m
	 
	Alert on high API latency alert: KubeAPILatencyHigh
	expr: |
	  max by(instance) (
	    kubernetes:job_verb_instance:apiserver_latency:pctl90rate5m
	      {verb=3D~"GET|POST|DELETE|PATCH"}
	  ) > 200
	for: 5m
```

Note that the Prometheus rules are taken from the already manifested jsonnet output, which can be found in [our sources][bitnami-labs/kubernetes-grafana-dashboards] and the thresholds are evaluated from $.slo.error_ratio_threshold and $.slo.latency_threshold respectively.

## Programmatically creating Grafana dashboards
Creating Grafana dashboards is usually done by interacting with the UI. This is fine for simple and/or "standard" dashboards (as for example, downloaded from https://grafana.com/dashboards), but becomes cumbersome if you want to implement best devops practices, especially for&nbsp;gitops workflows. The community is addressing this issue via efforts, such as Grafana libraries for jsonnet, python, and Javascript. For jsonnet implementation with grafana you can use grafonnet-lib.
With this jsonnet approach, we can re-use these jsonnet "libraries" to build many Grafana dashboards.   The <code>jsonnet files are a single source of truth for these dashboards and alerts.

referring to $.slo.error_ratio_threshold in our Grafana dashboards to set Grafana graph panel's thresholds property, as we did above for our Prometheus alert rules.
referring to created Prometheus recorded rules via jsonnet, an excerpt from [spec-kubeapi.jsonnet], note the metric.rules.requests_ratiorate_job_verb_code.record usage (instead of verbatim 'kubernetes:job_verb_code_instance:apiserver_requestratio_rate5m'): 

Graph showing all requests ratios
```
	req_ratio: $.grafana.common {
	  title: 'API requests ratios',
	  formula: metric.rules.requests_ratiorate_job_verb_code.record,
	  legend: '{{ verb }} - {{ code }}',
	},
```
	 
## References
* [Implementing Kubernetes SLOs in Prometheus and Grafana using jsonnet](https://engineering.bitnami.com/articles/implementing-slos-using-prometheus.htmlt)
* [srecon17_americas_slides_wilkinson.pdf](https://www.usenix.org/sites/default/files/conference/protected-files/srecon17_americas_slides_wilkinson.pdf)
