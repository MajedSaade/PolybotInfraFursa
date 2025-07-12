{{/*
Generate a name like <release-name>-<chart-name>
*/}}
{{- define "yolo.fullname" -}}
{{ include "yolo.name" . }}-{{ .Release.Name }}
{{- end }}

{{/*
Use the chart name
*/}}
{{- define "yolo.name" -}}
{{ .Chart.Name }}
{{- end }}
