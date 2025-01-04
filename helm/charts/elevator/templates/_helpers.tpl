{{- define "elevator.name" -}}
{{- default .Chart.Name .Values.nameOverride -}}
{{- end }}

{{- define "elevator.fullname" -}}
{{- printf "%s-%s" (include "elevator.name" .) .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}
