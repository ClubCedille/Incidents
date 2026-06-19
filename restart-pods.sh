kubectl get pod -A -o json \
| jq -r '                  
  .items[]
  | select(
      any(
        .status.containerStatuses[]?;
        .state.waiting.message? // "" | test("failed to stat")
      )
    )
  | [
      .metadata.namespace,
      .metadata.name,
      (.metadata.ownerReferences[]? | select(.kind=="ReplicaSet") | .name)
    ]
  | @tsv
' \
| while IFS=$'\t' read -r ns pod rs; do
    echo "Pod: $ns/$pod"

    kubectl delete pod "$pod" -n "$ns" --wait=false

    if [ -n "$rs" ]; then
        echo "ReplicaSet: $ns/$rs"
        kubectl delete rs "$rs" -n "$ns" --wait=false
    fi
done
