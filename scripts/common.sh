
#
# $(parse_lookup "$COUNTER" "$nodes")
# $lead_node
# $node_count
# $zookeeper_count
#

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

