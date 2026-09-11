# Federation Admin Auth Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Super-admin creates federations with email/password; federation_admin logs in via RBAC; remove societies; worker identity collects state/district.

**Architecture:** Admin `POST /api/admin/federations` creates `Cooperative` + bcrypt `User` (`adminRole: federation_admin`). Admin UI Add Federation modal. Cut society admin APIs/UI. Flutter identity + mapper send `state`/`district`.

**Tech Stack:** Express/Mongoose, bcryptjs, React/Vite admin, Flutter.

### Task 1: Backend create federation
### Task 2: Cut society admin routes
### Task 3: Admin Federations UI + adminRole fix + remove Societies
### Task 4: Flutter identity state/district + mapper
### Task 5: Smoke verify
