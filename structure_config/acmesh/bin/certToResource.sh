cat << EOF
apiVersion: v1
kind: Secret
metadata:
  name: default-certificate
  namespace: default

type: Opaque
data:
EOF

echo "  tls.crt: $(cat $1|base64 -w 0)"
echo "  tls.key: $(cat $2|base64 -w 0)"
