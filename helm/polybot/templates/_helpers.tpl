{{- define "polybot.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "polybot.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}
