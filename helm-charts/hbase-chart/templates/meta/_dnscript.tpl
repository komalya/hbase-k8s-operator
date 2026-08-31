{{- define "hbasecluster.dnscript" }}
#! /bin/bash
set -x -m

export HADOOP_LOG_DIR=$0
export HADOOP_CONF_DIR=$1
export HADOOP_HOME=$2
export USER=$(whoami)
export HADOOP_LOG_FILE=$HADOOP_LOG_DIR/hadoop-$USER-datanode-$(hostname).log

mkdir -p $HADOOP_LOG_DIR
touch $HADOOP_LOG_FILE

function shutdown() {
  while [[ ! -f "/lifecycle/rs-terminated" ]]; do echo "Waiting for regionserver to die"; sleep 2; done
  echo "Stopping datanode"
  # short buffer for the RS JVM to fully exit (WAL close + ZK session cleanup) before we stop DN
  sleep 5
  $HADOOP_HOME/bin/hdfs --daemon stop datanode
}

trap shutdown SIGTERM

# Refresh the  NN include-list so this DN is allowed to register.
# 5s gap between the two calls lets the first refresh settle before the second.
echo "Refreshing namenode include-list"
$HADOOP_HOME/bin/hdfs dfsadmin -refreshNodes || true
echo "Sleeping 5s before next refresh"
sleep 5
echo "Refreshing namenode include-list again"
$HADOOP_HOME/bin/hdfs dfsadmin -refreshNodes || true

exec $HADOOP_HOME/bin/hdfs datanode 2>&1 | tee -a $HADOOP_LOG_FILE &
PID=$!

DOMAIN_SOCKET=$($HADOOP_HOME/bin/hdfs getconf -confKey dfs.domain.socket.path)
DOMAIN_SOCKET=$(echo $DOMAIN_SOCKET | sed -e 's/_PORT/*/g')
while [ ! -e ${DOMAIN_SOCKET} ]; do sleep 1; done
touch /lifecycle/dn-started

wait $PID
{{- end }}
