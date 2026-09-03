# Plan: Attendance-blue theme tokens

## Files

1. `frontend/lib/app/theme/app_colors.dart` — full light/dark brand scales
2. `frontend/lib/app/theme/app_theme.dart` — overlay `0x1A01668F` → primary alpha
3. `frontend/lib/features/payments/services/razorpay_checkout_service.dart` — theme color hex

## Tasks

### 1. Rewrite AppColors primary/accent scales
- primary = `#2563EB`; scale 50–900 blue
- accent aliases → blue containers (no orange brand)
- neutrals/status as spec
- dark: primary400-ish `#60A5FA`, surfaces keep navy-slate not teal

### 2. Patch hardcoded brand hex
- theme overlay + Razorpay `#2563EB`

### 3. Verify
- `dart analyze` on touched files (no full app run required)
