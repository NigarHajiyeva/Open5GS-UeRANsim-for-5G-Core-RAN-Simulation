{{/*
Expand the name of the chart.
*/}}
{{- define "open5gs-5g.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "open5gs-5g.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "open5gs-5g.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "open5gs-5g.labels" -}}
helm.sh/chart: {{ include "open5gs-5g.chart" . }}
{{ include "open5gs-5g.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "open5gs-5g.selectorLabels" -}}
app.kubernetes.io/name: {{ include "open5gs-5g.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "open5gs-5g.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "open5gs-5g.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate FQDN for a service
Usage: {{ include "open5gs-5g.serviceFQDN" (dict "name" "amf" "root" .) }}
*/}}
{{- define "open5gs-5g.serviceFQDN" -}}
{{- printf "%s.%s.svc.cluster.local" .name .root.Values.global.namespace }}
{{- end }}
