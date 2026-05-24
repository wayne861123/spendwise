# Spendwise — 個人記帳應用程式規格文件

## 1. Concept & Vision

**Spendwise** 是一款為個人設計的記帳工具，介面乾淨有溫度，操作直覺不壓迫。它不是冰冷的數字表格，而是一個讓你願意每天都打開的財務伙伴——看見自己的消費模式、掌握金錢流向、慢慢建立健康的理財習慣。

---

## 2. Design Language

### Aesthetic Direction
**Warm Financial** — 金融應用的專業感，加上溫暖的琥珀色調。深色主視覺傳達信任感，琥珀金色作為亮點傳達成長與財富的意象。整體氛圍：沉穩、可信賴、帶點輕奢感。

### Color Palette
```
--bg-primary:    #0f172a   /* 深藏青：主背景 */
--bg-secondary:  #1e293b   /* 次背景：卡片 */
--bg-tertiary:   #334155   /* 輸入框 / hover */
--accent-amber:  #f59e0b   /* 琥珀金：主要亮點 */
--accent-warm:   #fbbf24   /* 暖金色：hover 狀態 */
--text-primary:  #f8fafc   /* 主文字 */
--text-secondary:#94a3b8   /* 次文字 */
--text-muted:    #64748b   /* 輔助文字 */
--border:        #334155   /* 邊框 */
--success:       #10b981   /* 收入 */
--danger:       #ef4444   /* 支出 */
--info:         #3b82f6   /* 資訊 */
```

### Typography
- **Headings**: `Plus Jakarta Sans` (700/600) — 現代幾何感，數字顯示清晰
- **Body**: `DM Sans` (400/500) — 舒適好讀，數字和中文均衡
- **Monospace (數字)**: `JetBrains Mono` — 金額數字清晰分明
- **Scale**: 12 / 14 / 16 / 20 / 24 / 32 / 48px

### Spatial System
- Base unit: 8px
- Card padding: 24px
- Section gap: 32px
- Border radius: 12px (cards), 8px (buttons), 6px (inputs)

### Motion Philosophy
- **Entrance**: 頁面元素 fade-in + slide-up，stagger 80ms，duration 300ms
- **Micro-interactions**: button hover scale(1.02)，card hover shadow 增強
- **Transitions**: 200-300ms ease-out，所有 UI 狀態改變平滑過渡
- **Charts**: 數值載入動畫從 0 漸進到實際值

### Visual Assets
- **Icons**: Lucide Icons (stroke weight 1.5，與文字層次呼應)
- **Charts**: Chart.js 甜甜圈圖 + 長條圖
- **Decorative**: 琥珀色漸層光澤，卡片微微玻璃質感 (backdrop-filter blur)
- **Logo**: 「Wise」變形文字 + 貨幣符号 icon，簡潔有力

---

## 3. Layout & Structure

### Desktop Layout (>= 1024px)
```
┌─────────────────────────────────────────────┐
│  Sidebar (240px fixed)  │  Main Content      │
│  ─ Logo                 │  ─ Top Bar          │
│  ─ Navigation           │  ─ Page Content     │
│    • Dashboard          │                     │
│    • Transactions       │                     │
│    • Categories         │                     │
│    • Reports            │                     │
│    • Settings           │                     │
│  ─ User Profile         │                     │
└─────────────────────────────────────────────┘
```

### Pages
1. **Landing / Auth** — 登入、註冊、驗證碼寄送
2. **Dashboard** — 當月總覽、支出收入卡、甜甜圈圖、近五筆記錄
3. **Transactions** — 完整交易列表（支援篩選、搜尋、新增/編輯/刪除）
4. **Categories** — 收支分類管理
5. **Reports** — 月報圖表、趨勢分析
6. **Settings** — 個人資料、密碼修改

### Responsive Strategy
第一版以電腦版為主 (>= 1024px)。Sidebar 在平板/手機可折疊或隱藏。

---

## 4. Features & Interactions

### 身份驗證
- **註冊**: 姓名、Email、密碼 (≥8字，含數字)、確認密碼。即時驗證 + 錯誤訊息。
- **登入**: Email + 密碼，「記住我」勾選。登入失敗顯示原因。
- **Session**: Flask session (stored server-side, signed cookie)，7天有效期。
- **OAuth (預留)**: Auth0 / Google OAuth 接入點已預留，等用戶啟用。
- **驗證 Email (預留)**: 驗證信寄送流程已預留。

### Dashboard
- **月度摘要卡**: 本月總收入、總支出、結餘，三卡片並排，差額以顏色區分
- **甜甜圈圖**: 按分類顯示支出比例，hover 顯示詳細金額與百分比
- **近五筆記錄**: 快速檢視最新交易，含分類 icon、金額、日期
- **本月趨勢長條圖**: 每日支出柱狀圖，快速看出哪天花了最多

### Transactions (交易管理)
- **新增交易**: Modal 彈窗，表單欄位：日期（預設今天）、類型（收入/支出）、金額、分類、備註（選填）
- **編輯**: 點擊資料列 → Modal 預填資料 → 修改儲存
- **刪除**: 二次確認 dialog
- **篩選**: 日期範圍、類型、分類篩選器
- **搜尋**: 即時搜尋備註關鍵字
- **列表**: 分頁顯示（每頁20筆），按日期倒序
- **空狀態**: 友好提示 + 新增按鈕

### Categories (分類管理)
- 預設分類：餐飲、交通、娛樂、購物、醫療、居住、薪水、其他（收入）/ 餐飲、交通、娛樂、購物、醫療、居住、其他（支出）
- 支援新增自訂分類（名稱 + emoji icon + 顏色）
- 編輯 / 刪除分類（刪除時轉移該分類的交易）

### Reports (報表)
- 月份選擇器，檢視歷史月報
- 當月收入 vs 支出長條圖
- 支出分類甜甜圈圖（同 Dashboard 互動）
- 跟前一個月相比的變化百分比

### Settings (設定)
- 修改姓名
- 修改密碼（需填寫舊密碼）
- 登出按鈕

---

## 5. Component Inventory

### Button
- **Primary**: amber 背景，白色文字；hover: scale(1.02) + 亮度提升
- **Secondary**: 透明背景，琥珀邊框；hover: 背景變半透明
- **Danger**: 紅色系，刪除動作
- **Ghost**: 無邊框純文字；hover: 背景微亮
- **Disabled**: 降低 opacity，cursor: not-allowed
- **Loading**: 顯示 spinner，禁用點擊

### Card
- 深色背景 (#1e293b)，border 1px (#334155)
- 12px 圓角，24px padding
- Hover 時邊框變亮 + 陰影輕微增強
- 可選：頂部琥珀色光澤條（用于重要卡片）

### Input Field
- 深色背景，淺色邊框，聚焦時琥珀色邊框
- 浮動 label 或 placeholder
- 錯誤狀態：紅色邊框 + 錯誤訊息文字
- 類型：text, email, password (含顯示/隱藏 toggle), date, number, textarea

### Modal
- 深色 overlay (rgba(0,0,0,0.6))，backdrop-filter blur
- 居中卡片，白色/亮色內容區
- 標題 + 內容 + 操作區
- ESC 或點 overlay 關閉
- 動畫：scale(0.95)→1 + fade

### Table (Transactions List)
- 斑駁纹背景（奇偶列不同）
- hover 列高亮
- Mobile 可橫向滾動

### Navigation Item
- Icon + Label
- Active: amber 左邊框 + 文字變白
- Hover: 背景微亮

### Toast Notification
- 右上角浮動通知
- 成功(綠)、錯誤(紅)、資訊(藍)
- 3秒自動消失，支援關閉

### Chart Components
- 甜甜圈圖：hover 扇區高亮 + tooltip
- 長條圖：hover 長條變亮 + tooltip
- 統一深色主題配色

---

## 6. Technical Approach

### Stack
- **Backend**: Python Flask + Gunicorn
- **Database**: SQLite (檔案型，部署最簡單)
- **ORM**: SQLAlchemy + Flask-SQLAlchemy
- **Auth**: Flask-Login (session-based) + Werkzeug (密碼 hash)
- **Frontend**: 原生 HTML + CSS + Vanilla JS (無需 npm build，適合 Render 部署)
- **Charts**: Chart.js CDN
- **Icons**: Lucide CDN

### Project Structure
```
spendwise/
├── app.py                 # Flask 應用程式入口
├── config.py              # 設定檔
├── requirements.txt       # Python 依賴
├── instance/
│   └── spendwise.db       # SQLite 資料庫（gitignore）
├── static/
│   ├── css/
│   │   └── style.css
│   └── js/
│       └── app.js
├── templates/
│   ├── base.html
│   ├── auth/
│   │   ├── login.html
│   │   └── register.html
│   ├── dashboard.html
│   ├── transactions.html
│   ├── categories.html
│   ├── reports.html
│   └── settings.html
└── migrations/            # 未來 DB migration
```

### Data Model
```
User
  - id (PK)
  - name
  - email (unique)
  - password_hash
  - created_at

Transaction
  - id (PK)
  - user_id (FK → User)
  - type: 'income' | 'expense'
  - amount (decimal)
  - category_id (FK → Category)
  - date
  - note
  - created_at

Category
  - id (PK)
  - user_id (FK → User, nullable for defaults)
  - name
  - icon (emoji)
  - color (hex)
  - type: 'income' | 'expense'
  - is_default (bool)
```

### API Endpoints
```
Auth:
  GET  /auth/login
  POST /auth/login
  GET  /auth/register
  POST /auth/register
  GET  /auth/logout

Dashboard:
  GET /

Transactions:
  GET    /transactions
  POST   /transactions/new
  PUT    /transactions/<id>/edit
  DELETE /transactions/<id>/delete
  GET    /transactions/filter

Categories:
  GET    /categories
  POST   /categories/new
  PUT    /categories/<id>/edit
  DELETE /categories/<id>/delete

Reports:
  GET /reports
  GET /reports/data?month=YYYY-MM

Settings:
  GET  /settings
  POST /settings/profile
  POST /settings/password
```

### Deploy on Render
- `runtime.txt`: `python-3.11`
- `requirements.txt`: Flask, gunicorn, flask-sqlalchemy, flask-login, werkzeug
- `gunicorn.conf.py`: bind 0.0.0.0:$PORT
- 免費方案限制：sleep 後會重啟，SQLite 檔案需注意（無 persistent disk 的 Free 層，建議日後遷移到 Render PostgreSQL）

### Security
- 密碼 bcrypt hash (werkzeug.security)
- CSRF protection via Flask-WTF
- Session 使用 secure cookie
- SQL 注入防護 via SQLAlchemy ORM
- XSS 防護 via Jinja2 autoescape