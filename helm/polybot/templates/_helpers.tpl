{{- define "polybot.name" -}}
{{- .Chart.Name -}}
{{- end }}

{{- define "polybot.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{- define "polybot.esoRoleArn" -}}
{{- if eq .Release.Namespace "prod" -}}
arn:aws:iam::228281126655:role/majed-k8s-eso-role-prod
{{- else -}}
arn:aws:iam::228281126655:role/majed-k8s-eso-role-dev
{{- end -}}
{{- end }}
