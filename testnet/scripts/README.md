# Republic AI Scripts

Các script nhỏ để quản lý node và validator, được tổ chức theo module để dễ bảo trì.

## Cấu trúc

```
scripts/
├── common.sh              # Functions và config chung (source bởi tất cả scripts)
├── install-node.sh         # Cài đặt và setup node
├── create-validator.sh    # Tạo validator
├── stake.sh               # Stake/delegate tokens
├── backup-keys.sh         # Backup keys
├── restore-keys.sh        # Restore keys từ backup
├── check-status.sh        # Check validator/sync status
├── unjail.sh              # Unjail validator
├── check-balance.sh       # Check balance
├── list-keys.sh           # List keys
└── create-key.sh          # Create/import key
```

## Cách sử dụng

### Qua menu chính
```bash
cd testnet
./validator-manager.sh
```

### Chạy trực tiếp từng script
```bash
# Install node
./scripts/install-node.sh

# Create validator
./scripts/create-validator.sh

# Check balance
./scripts/check-balance.sh
```

## common.sh

File `common.sh` chứa:
- Tất cả configuration (CHAIN_ID, GAS_PRICES, etc.)
- Common functions (print_info, print_error, exec_cmd, etc.)
- OS và Docker detection
- Helper functions (check_sync, detect_arch, etc.)

Tất cả scripts khác đều source file này:
```bash
source "$SCRIPT_DIR/common.sh"
```

## Lợi ích của cấu trúc này

1. **Dễ bảo trì**: Mỗi script chỉ làm một việc cụ thể
2. **Tái sử dụng**: Có thể chạy từng script độc lập
3. **Dễ test**: Test từng chức năng riêng biệt
4. **Dễ mở rộng**: Thêm script mới không ảnh hưởng script cũ
5. **Code sạch**: Không có code trùng lặp, tất cả dùng chung common.sh

## Thêm script mới

1. Tạo file mới trong `scripts/`
2. Source `common.sh` ở đầu file
3. Thêm function chính
4. Thêm vào menu trong `validator-manager.sh`

Example:
```bash
#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

my_function() {
    print_header "My Function"
    # Your code here
    read -p "Press Enter to continue..."
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && my_function
```
