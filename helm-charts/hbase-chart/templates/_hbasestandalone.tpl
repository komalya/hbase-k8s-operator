{{ define "com.flipkart.hbasestandalone" }}
apiVersion: kvstore.flipkart.com/v1
kind: HbaseStandalone
metadata:
  name: {{ .Values.service.name }}
  namespace: {{ .Values.namespace }}
spec:
  baseImage: {{ .Values.service.image }}
  fsgroup: {{ .Values.service.runAsGroup }}
  configuration:
    hbaseConfigName: {{ .Values.configuration.hbaseConfigName }}
    hbaseConfigMountPath: {{ .Values.configuration.hbaseConfigMountPath }}
    hbaseConfig:
      {{- $configPath := .Values.configuration.hbaseConfigRelPath }}
      {{- ($.Files.Glob $configPath).AsConfig | nindent 6 }}
    hadoopConfigName: hadoop-config
    hadoopConfigMountPath: /etc/hadoop
    hadoopConfig:
      {{- $configPath := .Values.configuration.hbaseConfigRelPath }}
      {{- ($.Files.Glob $configPath).AsConfig | nindent 6 }}
  standalone: 
    {{- $ports := list 16000 16010 16030 16020 2181}}
    {{- $portsArr := list $ports }}
    {{- $arg := list .Values.configuration.hbaseLogPath .Values.configuration.hbaseConfigMountPath .Values.configuration.hbaseHomePath .Values.configuration.hbaseConfigName }}
    {{- $args := list $arg }}
    {{- $standalonescript := include "hbasecluster.standalonescript" . | indent 6 }}
    {{- $scripts := list $standalonescript }}
    {{- $data := dict "Values" .Values "root" .Values.standalone "args" $args "scripts" $scripts "portsArr" $portsArr }}
    {{- include "hbasecluster.component" $data | indent 4 }}
{{- end }}