          lb_url=$(aws elbv2 describe-load-balancers --names yhsllm-app-lb --query "LoadBalancers[0].DNSName" --output text)
          echo "Load Balancer URL: http://$lb_url"
