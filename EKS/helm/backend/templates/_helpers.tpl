{{- define "backend.name" -}}
backend
{{- end }}

{{- define "backend.fullname" -}}
backend
{{- end }}

{{- define "backend.labels" -}}
app.kubernetes.io/name: backend
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "backend.selectorLabels" -}}
app.kubernetes.io/name: backend
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "backend.serviceAccountName" -}}
backend
{{- end }}