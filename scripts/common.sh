
#
# $(find_index "vm1" "$nodes")
# $(parse_lookup "$COUNTER" "$nodes")
# $lead_node
# $node_count
# $zookeeper_count
#

find_index() {
  l_count=0
  for l in $2; do
    let l_count=l_count+1
    if [ $1 == $l ]; then
      echo "$l_count"
    fi
  done
}

parse_lookup() {
  l_count=0
  for l in $2; do
    let l_count=l_count+1
    if [ $1 = $l_count ]; then
      echo "$l"
    fi
  done
}

lead_node=$(echo ${nodes} | awk '{print $1}')

node_count=0
for n in $nodes; do
  let node_count=node_count+1
done

zookeeper_count=0
for n in $zookeepers; do
  let zookeeper_count=zookeeper_count+1
done

run_driver() {
  scp -q ./$1 $3@$2:
  ssh $3@$2 "chmod 777 $1"
  ssh $3@$2 "./$1"
  if [ "$DEBUG" != true ]; then
    ssh $3@$2 "rm ./$1"
  fi
  rm ./$1
}

driver_header() {
  echo '#!/bin/bash' > $1
  echo '' >> $1
  echo '#----------------' >> $1
  echo '#' >> $1
  echo "# $2" >> $1
  echo '#' >> $1
  echo '#----------------' >> $1
}

