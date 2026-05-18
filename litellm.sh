#!/bin/bash
docker stop litellm || true
ip=$(ip -6 addr show scope global|grep /128|awk '{print $2}'|cut -d/ -f1|head -n1)
echo "Using IP: $ip"
cat >/tmp/litellm-$LOGNAME.yaml <<EOcfg
model_list:
  - model_name: litellm-instruct
    litellm_params:
      model: openai/Nemotron-3-Nano-30B-A3B-Q8_0
      api_base: http://[$ip]:8000
      api_key: "not-needed"
EOcfg
exec docker run \
    --pull=always \
    --name litellm \
    --detach \
    --rm \
    -v /tmp/litellm-$LOGNAME.yaml:/app/config.yaml:ro \
    --network=host \
    docker.litellm.ai/berriai/litellm:main-latest \
        --port 4000 \
        --host '::' \
        --config /app/config.yaml \
        --detailed_debug
