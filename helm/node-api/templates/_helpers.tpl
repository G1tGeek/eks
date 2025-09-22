{{/*
Return the chart name
*/}}
{{- define "node-api.name" -}}
{{- .Chart.Name -}}
{{- end -}}

{{/*
Return the fully qualified app name: release-name + chart-name
*/}}
{{- define "node-api.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Return standard labels
*/}}
{{- define "node-api.labels" -}}
app.kubernetes.io/name: {{ include "node-api.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
