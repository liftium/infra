{{- define "dispatcher.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end }}

{{- define "dispatcher.fullname" -}}
{{- printf "%s-%s" (include "dispatcher.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}
