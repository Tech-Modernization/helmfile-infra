local runbook_url = 'https://confluence.contino.io/display/CD/Runbooks';
{
  // General settings
  name:: 'myappapi',
  slo:: {
    target: 0.99,
    error_ratio_threshold: 0.01,
    latency_percentile: 90,
    latency_threshold: 200,
  },
  prometheus:: {
    alerts_common: {
      labels: {
        notify_to: 'slack',
        slack_channel: '#sre-alerts',
        severity: 'critical',
      },
      'for': '5m',
    },
  },
  grafana:: {
    title: 'SLO: CWOW API',
    tags: ['myapp', 'api', 'sla'],
    common: {
      extra+: { legend+: { rightSide: true } },
    },
    templates_custom: {
      availability_span: {
        // NOTE: will depend on prometheus retention time
        values: '10m,1h,1d,7d,21d,30d,90d',
        default: '7d',
        hide: '',
      },
      api_percentile: {
        values: '50, 90, 99',
        default: '%s' % [$.slo.latency_percentile],
        hide: '',
      },
      verb_excl: {
        values: $.metrics.myapp_api.verb_excl,
        default: $.metrics.myapp_api.verb_excl,
        hide: 'variable',
      },
    },
  },
  // Dictionary with metrics, keyed by service.
  // In this particular case: just myapp_api (api itself)
  // Each metric entry has 3 relevant keys:
  // - graphs: consumed by dash-myappapi.jsonnet to produce grafana dashboards (.json)
  // - rules: consumed by rules-myappapi.jsonnet to produce prometheus recorded rules (.rules.yml)
  // - alerts: consumed by alerts-myappapi.jsonnet to produce prometheus alert rules (.rules.yml)
  //
  // Pseudo convention, re: rules prefixes:
  // 'myapp:<...>'  normal recorded rule
  // 'myapp::<...>' ditto above, also intended to be federated, matching '.+::.+' regex
  metrics:: {
    myapp_api: {
      // General (opinionated) settings for this metric
      local metric = self,

      // We're explicitly excluding these verbs from graphing because they tend to be spiky:
      // - WATCH: API exported metrics show steady 8secs, guess it's so by implementation
      // - CONNECT, PROXY: depend on control-plane -> nodes connectivity
      verb_excl:: 'CONNECT|WATCH|PROXY',
      verb_slos:: 'GET|POST|DELETE|PATCH',
      name:: 'CWOW API',
      graphs: {
        // Singlestat showing the service availabilty (%) over selectable $availability_span
        // (grafana template variable)
        aa_availability: $.grafana.common {
          title: 'Availability over $availability_span',
          type: 'singlestat',
          legend: '{{ job }}',
          formula: |||
            sum_over_time(%s[$availability_span]) / sum_over_time(%s[$availability_span])
          ||| % [metric.rules.slo_ok.record, metric.rules.slo_sample.record],
          threshold: '%.2f' % $.slo.target,
          extra: { span: 2, format: 'percentunit', valueFontSize: '80%', legend+: { rightSide: false } },
        },
        // Singlestat showing time budget remaining from the selected $availability_span
        ab_availability: $.grafana.common {
          title: 'Budget remaining from $availability_span',
          type: 'singlestat',
          legend: '{{ job }}',
          // time remaining: (<availability_ratio> - <target>) * <time_period_secs>
          // <time_period_secs> is calculated as:
          //    current time() - timestamp(<any_metric offseted by time_period>)
          formula: |||
            scalar((sum_over_time(%s[$availability_span]) / sum_over_time(%s[$availability_span]) - %s)) * 
              scalar((time() - timestamp(up{job="prometheus"} offset $availability_span)))
          ||| % [
            metric.rules.slo_ok.record,
            metric.rules.slo_sample.record,
            $.slo.target,
          ],
          threshold: '%.2f' % $.slo.target,
          extra: { span: 2, format: 's', decimals: 2, valueFontSize: '80%', legend+: { rightSide: false } },
        },
        // Graph showing fixed short-span service availabilty ([10m])
        ac_availability: $.grafana.common {
          title: 'SLO: Availaibility over 10m',
          legend_rightSide: false,
          legend: '{{ job }}',
          formula: |||
            sum_over_time(%s[10m]) / sum_over_time(%s[10m])
          ||| % [metric.rules.slo_ok.record, metric.rules.slo_sample.record],
          threshold: '%.2f' % $.slo.target,
          extra: { span: 2 },
        },
        // Graph showing 500s except `verb_excl`
        ad_error_ratio: $.grafana.common {
          title: 'API non-200s/total ratio (except %s)' % [metric.verb_excl],
          formula: 'sum by (job, method, status, instance)(%s{method!~"%s", status!~"2.."})' % [
            metric.rules.requests_ratiorate_job_verb_code_instance.record,
            metric.verb_excl,
          ],
          legend: '{{ method }} - {{ status }} - {{ instance }}',
          threshold: $.slo.error_ratio_threshold,
          extra: { span: 6 },
        },
        // Graph showing all requests ratios
        ba_req_ratio: $.grafana.common {
          title: 'API requests ratios',
          formula: metric.rules.requests_ratiorate_job_verb_code.record,
          legend: '{{ method }} - {{ status }}',
          threshold: 1e9,
        },
        // Graph showing latency except `verb_excl`
        ca_latency: $.grafana.common {
          title: 'API $api_percentile-th latency[ms] by method (except %s)' % [metric.verb_excl],
          formula: '%s{method!~"%s"}' % [
            metric.rules.latency_job_verb_instance.record,
            metric.verb_excl,
          ],
          legend: '{{ method }} - {{ instance }}',
          threshold: $.slo.latency_threshold,
        },
      },
      alerts: {
        // Alert on 500s ratio above chosen `error_ratio_threshold` for `verb_slos`
        error_ratio: $.prometheus.alerts_common {
          local alert = self,
          name: 'CWOWAPIErrorRatioHigh',
          expr: 'sum by (instance)(%s{method=~"%s", status=~"5.."}) > %s' % [
            metric.rules.requests_ratiorate_job_verb_code_instance.record,
            metric.verb_slos,
            $.slo.error_ratio_threshold,
          ],
          annotations: {
            summary: 'CWOW API 500s ratio is High',
            description: |||
              Issue: CWOW API Error ratio on {{ $labels.instance }} is above %s: {{ $value }}
              Playbook: %s#%s
            ||| % [$.slo.error_ratio_threshold, runbook_url, alert.name],
          },
        },
        // Alert on 500s ratio above chosen `error_ratio_threshold` for `verb_slos`
        latency: $.prometheus.alerts_common {
          local alert = self,
          name: 'CWOWAPILatencyHigh',
          expr: 'max by (instance)(%s{method=~"%s"}) > %s' % [
            metric.rules.latency_job_verb_instance.record,
            metric.verb_slos,
            $.slo.latency_threshold,
          ],
          annotations: {
            summary: 'CWOW API Latency is High',
            description: |||
              Issue: CWOW API Latency on {{ $labels.instance }} is above %s ms: {{ $value }}
              Playbook: %s#%s
            ||| % [$.slo.latency_threshold, runbook_url, alert.name],
          },
        },
        blackbox: $.prometheus.alerts_common {
          local alert = self,
          name: 'CWOWAPIUnHealthy',
          expr: 'probe_success{provider="myapp"} == 0',
          annotations: {
            summary: 'CWOW API is unhealthy',
            description: |||
              Issue: CWOW API is not responding 200s from blackbox.monitoring
              Playbook: %s#%s
            ||| % [runbook_url, alert.name],
          },
        },
      },
      // Recorded rules
      rules: {
        common:: { labels+: { job: 'myapp_api_slo' } },
        // ### Rates ###
        // Create several r-rules from rate() over http_server_requests_seconds_count,
        // with different label sets

        // Requests rate by all reasonable labels
        requests_rate_job_verb_code_instance: self.common {
          record: 'myapp:job_verb_code_instance:apiserver_requests:rate5m',
          expr: 'sum by (job, method, status, instance)(rate(http_server_requests_seconds_count[5m]))',
        },
        // Requests ratio_rate by all reasonable labels
        requests_ratiorate_job_verb_code_instance: self.common {
          record: 'myapp:job_verb_code_instance:apiserver_requests:ratio_rate5m',
          expr: '%s / ignoring(method, status) group_left sum by (job, instance)(%s)' % [
            metric.rules.requests_rate_job_verb_code_instance.record,
            metric.rules.requests_rate_job_verb_code_instance.record,
          ],
        },
        // Requests rate without instance, intended for federation / LT-storage
        requests_rate_job_verb_code: self.common {
          record: 'myapp::job_verb_code:apiserver_requests:rate5m',
          expr: 'sum without (instance)(%s)' % [
            metric.rules.requests_rate_job_verb_code_instance.record,
          ],
        },
        // Requests ratio_rate without instance, intended for federation / LT-storage
        requests_ratiorate_job_verb_code: self.common {
          record: 'myapp::job_verb_code:apiserver_requests:ratio_rate5m',
          expr: 'sum without (instance)(%s)' % [
            metric.rules.requests_ratiorate_job_verb_code_instance.record,
          ],
        },
        // Useful for SLO and long-term views: job (only for `verb_slos`)
        slo_errors_ratiorate_job: self.common {
          record: 'myapp:job:apiserver_request_errors:ratio_rate5m',
          expr: 'sum by (job)(%s{method=~"%s", status=~"5.."})' % [
            metric.rules.requests_ratiorate_job_verb_code_instance.record,
            metric.verb_slos,
          ],
        },

        // ### Latency ###
        // Create several r-rules from histogram_quantile() over  http_server_requests_seconds_sum 

        // Useful for dashboards: job, verb, instance
        latency_job_verb_instance: self.common {
          record: 'myapp:job_verb_instance:apiserver_latency:pctl%srate5m' % $.slo.latency_percentile,
          expr: |||
            histogram_quantile (
              0.%s,
              sum by (env, job, method, instance)(
                rate(http_server_requests_seconds_sum[5m])
              )
            ) / 1e3
          ||| % [$.slo.latency_percentile],
        },
        // Useful for alerting: job, method/verb
        latency_job_verb: self.common {
          record: 'myapp:job_verb:http_server_requests_seconds_sum:pctl%srate5m' % $.slo.latency_percentile,
          expr: |||
            histogram_quantile (
              0.%s,
              sum by (env, method)(
                rate(http_server_requests_seconds_sum[5m])
              )
            ) / 1e3 > 0
          ||| % [$.slo.latency_percentile],
        },

        // Useful for SLO and long-term views: job (only for `verb_slos`)
        slo_latency_job: self.common {
          record: 'myapp::job:apiserver_latency:pctl%srate5m' % $.slo.latency_percentile,
          expr: |||
            histogram_quantile (
              0.%s,
              sum by (env, job)(
                rate(http_server_requests_seconds_sum{method=~"%s"}[5m])
              )
            ) / 1e3
          ||| % [$.slo.latency_percentile, metric.verb_slos],
        },
        probe_success: self.common {
          record: 'myapp::job:probe_success',
          expr: |||
            sum by()(probe_success{provider="myapp", component="apiserver"})
          |||,
        },

        // SLOs: error ratio and latency below thresholds
        // The purpose of below metrics is to allow answering the question:
        //   How has this SLO done in the past <N> days ?
        //
        // As prometheus-2.3.x can't do e.g.:
        //   sum_over_time(myapp::job:slo_myapp_api_ok[30d]) /
        //   sum_over_time(myapp::job:slo_myapp_api_ok[30d] > -Inf)
        // b/c _over_time(<formula>) is not valid, but only plain _over_time(<metric>[time]),
        // so we create `slo_myapp_api_sample` as a way to provide all-1's, to be able to:
        //   sum_over_time(myapp::job:slo_myapp_api_ok[30d]) /
        //   sum_over_time(myapp::job:slo_myapp_api_sample[30d])

        // metric to capture "SLO Ok"
        slo_ok: self.common {
          record: 'myapp::job:slo_myapp_api_ok',
          expr: |||
            %s < bool %s * %s < bool %s
          ||| % [
            metric.rules.slo_errors_ratiorate_job.record,
            $.slo.error_ratio_threshold,
            metric.rules.slo_latency_job.record,
            $.slo.latency_threshold,
          ],
        },
        // metric always evaluating to 1 (with same labels as above)
        slo_sample: self.common {
          record: 'myapp::job:slo_myapp_api_sample',
          expr: |||
            %s < bool Inf * %s < bool Inf
          ||| % [
            metric.rules.slo_errors_ratiorate_job.record,
            metric.rules.slo_latency_job.record,
          ],
        },
      },
    },
  },
}
