# Fixly theme → attendance-app blue palette

Approved: option A (full match reference UI).

## Goal

Replace Fixly teal `#01668F` + orange `#FD6E01` brand pair with royal-blue primary system matching the attendance/scheduling mock.

## Light tokens

| Role | Hex |
|------|-----|
| Primary | `#2563EB` |
| Primary scale | `#EFF6FF` … `#1E3A8A` |
| Accent / secondary | same blue family (CTA = primary) |
| Background | `#F8FAFC` |
| Surface | `#FFFFFF` |
| Text primary / secondary | `#1E293B` / `#64748B` |
| Success / warning / error | `#10B981` / `#F59E0B` / `#DC2626` |

## Dark

Desaturated/lighter blue tonals for primary; keep existing dark neutral structure adjusted for contrast (not inverted light UI).

## Scope

- In: `app_colors.dart`, hardcoded brand hex in theme/payments if any
- Out: layout, radius, typography, feature redesign

## Success

App light theme reads as cool grey + white cards + royal blue headers/CTAs/nav; orange no longer brand accent.
