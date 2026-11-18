{{- define "mcp-shared-gateway.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mcp-shared-gateway.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "mcp-shared-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "mcp-shared-gateway.labels" -}}
helm.sh/chart: {{ include "mcp-shared-gateway.chart" . }}
app.kubernetes.io/name: {{ include "mcp-shared-gateway.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "mcp-shared-gateway.tlsSecretName" -}}
{{- if .Values.certificate.secretName }}
{{- .Values.certificate.secretName }}
{{- else }}
{{- .Values.tls.secretName }}
{{- end }}
{{- end }}
