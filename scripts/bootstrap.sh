#!/bin/bash
set -e

# ==============================================================================
# SETUP FUNCTION: Dùng chung cho cả 2 tier
# ==============================================================================
setup_cluster() {
  local CLUSTER_NAME=$1
  local PORT=$2
  local ROOT_FILE=$3
  
  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║ SETUP CLUSTER: $CLUSTER_NAME (port $PORT)"
  echo "╚════════════════════════════════════════════════════════════════╝"
  
  # 1. Tạo cluster
  echo "📦 [1/8] Tạo cluster $CLUSTER_NAME..."
  kubectl config use-context kind-${CLUSTER_NAME} 2>/dev/null || \
    kind create cluster --name ${CLUSTER_NAME} --config kind-${CLUSTER_NAME}.yaml
  kubectl config use-context kind-${CLUSTER_NAME}
  
  # 2. Cài Gateway API CRDs
  echo "🚪 [2/8] Cài đặt Gateway API CRDs..."
  kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.5.1/standard-install.yaml
  
  # 3. Cài ArgoCD
  echo "⚙️  [3/8] Cài đặt ArgoCD (>= 3.1)..."
  kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
  kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  
  # 4. Thêm Helm OCI repo
  echo "📚 [4/8] Thêm Helm OCI repository cho kgateway..."
  # Chờ argocd-server sẵn sàng
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || true
  
  # Thêm OCI repo (skip nếu đã tồn tại)
  argocd repo add cr.kgateway.dev/kgateway-dev/charts --type helm --enable-oci 2>/dev/null || true
  
  # 5. Bật insecure mode
  echo "🔓 [5/8] Bật insecure mode để expose qua gateway..."
  kubectl -n argocd patch configmap argocd-cmd-params-cm --type merge \
    -p '{"data":{"server.insecure":"true"}}' || true
  kubectl -n argocd rollout restart deploy argocd-server || true
  sleep 5
  
  # 6. Apply root Application
  echo "🎯 [6/8] Apply root-${CLUSTER_NAME}.yaml..."
  kubectl apply -f ${ROOT_FILE}
  
  # 7. Lấy admin password
  echo "🔐 [7/8] Admin password ArgoCD (cluster: $CLUSTER_NAME):"
  echo "   Username: admin"
  echo "   Password: $(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 --decode)"
  
  # 8. Port-forward (background)
  echo "🌐 [8/8] Setup port-forward (port $PORT)..."
  # Kill existing port-forward
  lsof -ti:${PORT} 2>/dev/null | xargs kill -9 2>/dev/null || true
  sleep 1
  
  # Start port-forward in background
  kubectl -n argocd port-forward svc/argocd-server ${PORT}:80 > /dev/null 2>&1 &
  echo "   ✅ ArgoCD UI: http://localhost:${PORT}"
}

# ==============================================================================
# PHẦN CHÍNH: Setup cả 2 cụm
# ==============================================================================

# Tắt lỗi tạm thời để check cluster tồn tại
set +e
kind get clusters | grep -q nonproduction
NONPROD_EXISTS=$?
kind get clusters | grep -q production
PROD_EXISTS=$?
set -e

# Setup non-production
if [ $NONPROD_EXISTS -ne 0 ]; then
  setup_cluster "nonproduction" "9090" "root-nonproduction.yaml"
else
  echo "⚠️  Cluster 'nonproduction' đã tồn tại, skip tạo mới"
  kubectl config use-context kind-nonproduction
  echo "🎯 Apply root-nonproduction.yaml..."
  kubectl apply -f root-nonproduction.yaml
fi

# Setup production
if [ $PROD_EXISTS -ne 0 ]; then
  setup_cluster "production" "9091" "root-production.yaml"
else
  echo "⚠️  Cluster 'production' đã tồn tại, skip tạo mới"
  kubectl config use-context kind-production
  echo "🎯 Apply root-production.yaml..."
  kubectl apply -f root-production.yaml
fi

# ==============================================================================
# KẾT THÚC
# ==============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║ ✅ SETUP HOÀN THÀNH - CẢ 2 CỤM READY"
echo "╠════════════════════════════════════════════════════════════════╣"
echo "║ Non-Prod (dev+staging):  http://localhost:9090"
echo "║ Production (prod):       http://localhost:9091"
echo "║"
echo "║ Chuyển context:"
echo "║   kubectl config use-context kind-nonproduction"
echo "║   kubectl config use-context kind-production"
echo "║"
echo "║ Kiểm tra status:"
echo "║   kubectl -n argocd get pods"
echo "║   kubectl -n argocd get apps"
echo "╚════════════════════════════════════════════════════════════════╝"