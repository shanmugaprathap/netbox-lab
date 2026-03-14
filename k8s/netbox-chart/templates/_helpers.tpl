{{/*
Expand the name of the chart.
*/}}
{{- define "netbox-lab.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "netbox-lab.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "netbox-lab.labels" -}}
helm.sh/chart: {{ include "netbox-lab.name" . }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "netbox-lab.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "netbox-lab.selectorLabels" -}}
app.kubernetes.io/name: {{ include "netbox-lab.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
PostgreSQL host (Bitnami naming convention)
*/}}
{{- define "netbox-lab.postgresql.host" -}}
{{ .Release.Name }}-postgresql
{{- end }}

{{/*
Redis Tasks host (Bitnami naming convention)
*/}}
{{- define "netbox-lab.redis-tasks.host" -}}
{{ .Release.Name }}-redis-tasks-master
{{- end }}

{{/*
Redis Cache host (Bitnami naming convention)
*/}}
{{- define "netbox-lab.redis-cache.host" -}}
{{ .Release.Name }}-redis-cache-master
{{- end }}
