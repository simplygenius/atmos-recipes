output "kubecfg-cluster" {
  description = <<-EOF
   Apply this config to allow the kubecfg client to talk to the cluster.
   Can be applied by:
    * Directly editing ~/.kube/config
    * Running 'aws eks update-kubeconfig'
    * Saving to a yaml file and running 'kubectl apply -f saved.yaml'
EOF


  value = <<EOF
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority[0].data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${aws_eks_cluster.cluster.name}"
EOF

}

output "kubecfg-node" {
  description = <<-EOF
   Apply this config to allow worker nodes to join the the cluster.
   Can be applied by:
    * Saving to a yaml file and running 'kubectl apply -f saved.yaml'
EOF


  value = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${data.aws_iam_role.node_role.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
EOF

}

output "aws_eks_ami" {
  value = data.aws_ami.worker.image_id
}

output "user_data" {
  description = "The user data used to provision an EKS worker node that is running the aws eks ami"
  value       = <<EOF
#!/bin/bash
/etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.cluster.endpoint}' --b64-cluster-ca '${aws_eks_cluster.cluster.certificate_authority[0].data}' '${aws_eks_cluster.cluster.name}'
EOF

}

output "node_security_group" {
  description = "The security group that compute nodes need to be attached to"
  value       = aws_security_group.node.id
}

output "cluster_name" {
  description = "The cluster name"
  value       = aws_eks_cluster.cluster.name
}

