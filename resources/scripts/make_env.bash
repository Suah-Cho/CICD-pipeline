MODE=$1

KEY_VAULT_NAME="croft-gp-kv"  # Key Vault 이름을 입력하세요.
OUTPUT_FILE="$MODE.env"  # 출력할 env 파일 이름

# 기존 .env 파일 삭제 (새로 생성하기 위해)
rm -rf $OUTPUT_FILE

if [ -z "$MODE" ]; then
   MODE="test"
fi

echo "Starting to fetch secrets for mode=$MODE"

# Key Vault에서 mode 태그가 일치하는 시크릿 목록 가져오기
for secret_id in $(az keyvault secret list --vault-name $KEY_VAULT_NAME --query "[?tags.mode && contains(tags.mode, '$MODE')].id" -o tsv); do
    # 시크릿 이름과 값을 가져옵니다.
    secret_name=$(basename $secret_id)
    secret_name=$(echo $secret_name | sed 's/^GP-DEV-//; s/^GP-PROD-//; s/-/_/g')
    secret_value=$(az keyvault secret show --id $secret_id --query "value" -o tsv)

    # .env 파일 형식으로 출력
    echo "${secret_name}=${secret_value}" >> $OUTPUT_FILE
done

hostname=$(hostname)
echo "VM_HOSTNAME=${hostname}" >> $OUTPUT_FILE

# 파일 존재 여부 확인
if [ -f "$OUTPUT_FILE" ]; then
    echo "모든 시크릿이 $OUTPUT_FILE 파일에 저장되었습니다. (mode=$MODE)"
    echo "파일 경로: $(realpath $OUTPUT_FILE)"
else
    echo "ERROR: $OUTPUT_FILE 파일이 생성되지 않았습니다."
fi