/* ============================================================
   Spendwise - App JavaScript
   ============================================================ */

// Initialize Lucide icons
document.addEventListener('DOMContentLoaded', () => {
    if (window.lucide) lucide.createIcons();
    initSidebar();
    initPasswordToggles();
    initModals();
    initToasts();
});

// ============================================================
// Sidebar
// ============================================================
function initSidebar() {
    const sidebar = document.getElementById('sidebar');
    const mobileBtn = document.getElementById('mobile-menu-btn');
    const overlay = document.getElementById('sidebar-overlay');

    if (!sidebar) return;

    function openSidebar() {
        sidebar.classList.add('open');
        if (overlay) overlay.classList.add('active');
        document.body.style.overflow = 'hidden';
    }

    function closeSidebar() {
        sidebar.classList.remove('open');
        if (overlay) overlay.classList.remove('active');
        document.body.style.overflow = '';
    }

    if (mobileBtn) mobileBtn.addEventListener('click', openSidebar);
    if (overlay) overlay.addEventListener('click', closeSidebar);

    // Re-init icons in sidebar
    if (window.lucide) lucide.createIcons();
}

// ============================================================
// Password Toggle
// ============================================================
function initPasswordToggles() {
    document.querySelectorAll('.password-toggle').forEach(btn => {
        btn.addEventListener('click', () => {
            const input = btn.parentElement.querySelector('input');
            if (!input) return;
            if (input.type === 'password') {
                input.type = 'text';
                btn.innerHTML = '<i data-lucide="eye-off"></i>';
            } else {
                input.type = 'password';
                btn.innerHTML = '<i data-lucide="eye"></i>';
            }
            if (window.lucide) lucide.createIcons();
        });
    });
}

// ============================================================
// Modal System
// ============================================================
function initModals() {
    document.querySelectorAll('[data-close-modal]').forEach(el => {
        el.addEventListener('click', closeModal);
    });
    document.addEventListener('keydown', e => {
        if (e.key === 'Escape') closeModal();
    });
}

function openModal(title, bodyHTML, footerHTML) {
    const modal = document.getElementById('base-modal');
    if (!modal) return;

    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-body').innerHTML = bodyHTML;
    document.getElementById('modal-footer').innerHTML = footerHTML;

    modal.classList.add('open');
    document.body.style.overflow = 'hidden';

    if (window.lucide) lucide.createIcons();
    initPasswordToggles();
}

function closeModal() {
    const modal = document.getElementById('base-modal');
    if (!modal) return;
    modal.classList.remove('open');
    document.body.style.overflow = '';
}

// ============================================================
// Toast Notifications
// ============================================================
function initToasts() {
    // Auto-remove toasts after 4 seconds
    const toasts = document.querySelectorAll('.toast');
    toasts.forEach(toast => {
        setTimeout(() => toast.remove(), 4000);
    });
}

function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `toast toast-${type}`;
    toast.innerHTML = `
        <span>${message}</span>
        <button class="toast-close" onclick="this.parentElement.remove()">&times;</button>
    `;
    container.appendChild(toast);

    setTimeout(() => toast.remove(), 4000);
}

// ============================================================
// Transaction Modal
// ============================================================
async function openTransactionModal(id = null) {
    const title = id ? '編輯交易' : '新增交易';
    const cats = await fetchCategories();

    const expenseOptions = cats.expense.map(c => `<option value="${c.id}">${c.icon} ${c.name}</option>`).join('');
    const incomeOptions = cats.income.map(c => `<option value="${c.id}">${c.icon} ${c.name}</option>`).join('');

    const bodyHTML = `
        <form id="transaction-form" novalidate>
            <input type="hidden" name="csrf_token" value="${getCsrfToken()}">
            ${id ? `<input type="hidden" name="id" value="${id}">` : ''}
            <div class="form-group">
                <label for="trans-type">類型</label>
                <select id="trans-type" name="type" class="form-input" required>
                    <option value="expense" selected>支出</option>
                    <option value="income">收入</option>
                </select>
            </div>
            <div class="form-group">
                <label for="trans-amount">金額 (NT$)</label>
                <input type="number" id="trans-amount" name="amount" class="form-input" placeholder="0.00" step="0.01" min="0.01" required>
            </div>
            <div class="form-group">
                <label for="trans-category">分類</label>
                <select id="trans-category" name="category_id" class="form-input" required>
                    ${expenseOptions}
                </select>
            </div>
            <div class="form-group">
                <label for="trans-date">日期</label>
                <input type="date" id="trans-date" name="date" class="form-input" value="${new Date().toISOString().split('T')[0]}" required>
            </div>
            <div class="form-group">
                <label for="trans-note">備註 (選填)</label>
                <input type="text" id="trans-note" name="note" class="form-input" placeholder="optional note..." maxlength="255">
            </div>
        </form>
    `;

    const footerHTML = `
        <button class="btn btn-ghost" onclick="closeModal()">取消</button>
        <button class="btn btn-primary" onclick="submitTransaction(${id ? id : 'null'})">
            <i data-lucide="check"></i>
            儲存
        </button>
    `;

    openModal(title, bodyHTML, footerHTML);

    // Store both category arrays for type switching
    window._expenseCats = cats.expense;
    window._incomeCats = cats.income;

    // Type switch updates categories
    document.getElementById('trans-type').addEventListener('change', function () {
        const catSelect = document.getElementById('trans-category');
        const cats = this.value === 'income' ? window._incomeCats : window._expenseCats;
        catSelect.innerHTML = cats.map(c => `<option value="${c.id}">${c.icon} ${c.name}</option>`).join('');
    });

    if (id) {
        loadTransaction(id);
    }
}

async function loadTransaction(id) {
    const row = document.querySelector(`tr[data-id="${id}"]`);
    if (!row) return;

    const type = row.querySelector('.transaction-type-badge').classList.contains('income') ? 'income' : 'expense';
    const amount = row.querySelector('.amount-income, .amount-expense').textContent.replace(/[^0-9.]/g, '');
    const catBadge = row.querySelector('.category-badge');
    const date = row.querySelector('td:first-child').textContent.trim();
    const note = catBadge ? catBadge.nextSibling ? catBadge.nextSibling.textContent.trim() : '' : '';

    document.getElementById('trans-type').value = type;
    document.getElementById('trans-amount').value = amount;
    document.getElementById('trans-date').value = date;
    document.getElementById('trans-note').value = note === '—' ? '' : note;

    // Update categories for this type
    const allCats = await fetchCategories();
    const cats = type === 'income' ? allCats.income : allCats.expense;
    const catSelect = document.getElementById('trans-category');
    catSelect.innerHTML = cats.map(c => `<option value="${c.id}">${c.icon} ${c.name}</option>`).join('');

    // Try to select the right category from the text
    const catName = catBadge ? catBadge.textContent.trim().split(' ').slice(1).join(' ').trim() : '';
    if (catName) {
        const catOption = Array.from(catSelect.options).find(o => o.textContent.includes(catName));
        if (catOption) catSelect.value = catOption.value;
    }
}

async function fetchCategories() {
    try {
        const resp = await fetch('/api/categories/list', {
            headers: { 'Accept': 'application/json', 'X-Requested-With': 'XMLHttpRequest' }
        });
        if (resp.ok) {
            const data = await resp.json();
            return data;
        }
    } catch (e) {}
    // Fallback: parse from page
    return { income: [], expense: [] };
}

async function submitTransaction(id) {
    const form = document.getElementById('transaction-form');
    const formData = new FormData(form);
    const csrf = getCsrfToken();

    const type = formData.get('type');
    const amount = formData.get('amount');
    const category_id = formData.get('category_id');
    const date = formData.get('date');
    const note = formData.get('note');

    // Basic validation
    const amountNum = parseFloat(amount);
    if (!amount || isNaN(amountNum) || amountNum < 0.01) {
        showToast('請輸入有效金額（需大於 0）', 'error');
        return;
    }
    if (!date) {
        showToast('請選擇日期', 'error');
        return;
    }
    if (!category_id || category_id === '') {
        showToast('請選擇分類', 'error');
        return;
    }

    const url = id ? `/api/transactions/${id}` : '/api/transactions';
    const method = id ? 'PUT' : 'POST';

    try {
        const resp = await fetch(url, {
            method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({ type, amount: amountNum, category_id: parseInt(category_id), date, note })
        });

        const data = await resp.json();
        if (data.success) {
            showToast(data.message, 'success');
            closeModal();
            setTimeout(() => window.location.reload(), 500);
        } else {
            showToast(typeof data.message === 'string' ? data.message : Object.values(data.message)[0], 'error');
        }
    } catch (e) {
        showToast('發生錯誤，請稍後再試', 'error');
    }
}

async function editTransaction(id) {
    await openTransactionModal(id);
}

function confirmDeleteTransaction(id) {
    const bodyHTML = `
        <div class="confirm-dialog">
            <p>確定要刪除這筆記錄嗎？此動作無法復原。</p>
            <div class="confirm-actions">
                <button class="btn btn-ghost" onclick="closeModal()">取消</button>
                <button class="btn btn-danger" onclick="deleteTransaction(${id})">
                    <i data-lucide="trash-2"></i>
                    刪除
                </button>
            </div>
        </div>
    `;
    openModal('刪除交易', bodyHTML, '');
}

async function deleteTransaction(id) {
    const csrf = getCsrfToken();
    try {
        const resp = await fetch(`/api/transactions/${id}`, {
            method: 'DELETE',
            headers: { 'X-CSRFToken': csrf, 'X-Requested-With': 'XMLHttpRequest' }
        });
        const data = await resp.json();
        if (data.success) {
            showToast(data.message, 'success');
            closeModal();
            setTimeout(() => window.location.reload(), 500);
        } else {
            showToast(data.message, 'error');
        }
    } catch (e) {
        showToast('發生錯誤', 'error');
    }
}

// ============================================================
// Category Modal
// ============================================================
function openCategoryModal(id = null) {
    const title = id ? '編輯分類' : '新增分類';
    const card = id ? document.querySelector(`.category-card[data-id="${id}"]`) : null;
    const type = card ? card.dataset.type : 'expense';

    const bodyHTML = `
        <form id="category-form" novalidate>
            <input type="hidden" name="csrf_token" value="${getCsrfToken()}">
            <div class="form-group">
                <label for="cat-type">類型</label>
                <select id="cat-type" name="type" class="form-input" required>
                    <option value="expense" ${type === 'expense' ? 'selected' : ''}>支出</option>
                    <option value="income" ${type === 'income' ? 'selected' : ''}>收入</option>
                </select>
            </div>
            <div class="form-group">
                <label for="cat-name">分類名稱</label>
                <input type="text" id="cat-name" name="name" class="form-input" placeholder="例如：飲料" maxlength="50" required value="${card ? card.dataset.name : ''}">
            </div>
            <div class="form-group">
                <label for="cat-icon">圖示 (Emoji)</label>
                <input type="text" id="cat-icon" name="icon" class="form-input" placeholder="例如：🧋" maxlength="10" value="${card ? card.dataset.icon : '💰'}">
            </div>
            <div class="form-group">
                <label for="cat-color">顏色代碼</label>
                <div style="display:flex; gap:8px; align-items:center;">
                    <input type="text" id="cat-color" name="color" class="form-input" placeholder="#f59e0b" maxlength="7" value="${card ? card.dataset.color : '#f59e0b'}">
                    <input type="color" id="cat-color-picker" value="${card ? card.dataset.color : '#f59e0b'}" style="width:44px; height:44px; border:none; background:none; cursor:pointer; border-radius:8px; padding:0;">
                </div>
            </div>
        </form>
    `;

    const footerHTML = `
        <button class="btn btn-ghost" onclick="closeModal()">取消</button>
        <button class="btn btn-primary" onclick="submitCategory(${id ? id : 'null'})">
            <i data-lucide="check"></i>
            儲存
        </button>
    `;

    openModal(title, bodyHTML, footerHTML);

    // Sync color picker with text input
    const colorInput = document.getElementById('cat-color');
    const colorPicker = document.getElementById('cat-color-picker');
    colorInput.addEventListener('input', () => { colorPicker.value = colorInput.value; });
    colorPicker.addEventListener('input', () => { colorInput.value = colorPicker.value; });
}

function editCategory(id) {
    openCategoryModal(id);
}

async function submitCategory(id) {
    const form = document.getElementById('category-form');
    const formData = new FormData(form);
    const csrf = getCsrfToken();

    const name = formData.get('name');
    const icon = formData.get('icon') || '💰';
    const color = formData.get('color') || '#f59e0b';
    const type = formData.get('type');

    if (!name || name.trim().length === 0) {
        showToast('請輸入分類名稱', 'error');
        return;
    }

    const url = id ? `/api/categories/${id}` : '/api/categories';
    const method = id ? 'PUT' : 'POST';

    try {
        const resp = await fetch(url, {
            method,
            headers: {
                'Content-Type': 'application/json',
                'X-CSRFToken': csrf,
                'X-Requested-With': 'XMLHttpRequest'
            },
            body: JSON.stringify({ name, icon, color, type })
        });

        const data = await resp.json();
        if (data.success) {
            showToast(data.message, 'success');
            closeModal();
            setTimeout(() => window.location.reload(), 500);
        } else {
            showToast(typeof data.message === 'string' ? data.message : Object.values(data.message)[0], 'error');
        }
    } catch (e) {
        showToast('發生錯誤，請稍後再試', 'error');
    }
}

function confirmDeleteCategory(id) {
    const bodyHTML = `
        <div class="confirm-dialog">
            <p>確定要刪除此分類嗎？該分類的交易將會移至「其他」。</p>
            <div class="confirm-actions">
                <button class="btn btn-ghost" onclick="closeModal()">取消</button>
                <button class="btn btn-danger" onclick="deleteCategory(${id})">
                    <i data-lucide="trash-2"></i>
                    刪除
                </button>
            </div>
        </div>
    `;
    openModal('刪除分類', bodyHTML, '');
}

async function deleteCategory(id) {
    const csrf = getCsrfToken();
    try {
        const resp = await fetch(`/api/categories/${id}`, {
            method: 'DELETE',
            headers: { 'X-CSRFToken': csrf, 'X-Requested-With': 'XMLHttpRequest' }
        });
        const data = await resp.json();
        if (data.success) {
            showToast(data.message, 'success');
            closeModal();
            setTimeout(() => window.location.reload(), 500);
        } else {
            showToast(data.message, 'error');
        }
    } catch (e) {
        showToast('發生錯誤', 'error');
    }
}

// ============================================================
// Helpers
// ============================================================
function getCsrfToken() {
    const el = document.querySelector('meta[name="csrf-token"]') ||
              document.querySelector('input[name="csrf_token"]');
    return el ? el.value : '';
}

// ============================================================
// Auth Form Enhancements
// ============================================================
document.querySelectorAll('.auth-form').forEach(form => {
    const submitBtn = form.querySelector('button[type="submit"]');
    if (!submitBtn) return;

    form.addEventListener('submit', () => {
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<span class="spinner"></span> 處理中...';
    });
});