from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify, current_app
from flask_login import login_user, logout_user, login_required, current_user
from datetime import datetime, timedelta
import logging
from sqlalchemy import func, extract
from models import db, User, Category, Transaction
from forms import RegisterForm, LoginForm, TransactionForm, CategoryForm, ProfileForm, PasswordForm

main = Blueprint('main', __name__)
auth = Blueprint('auth', __name__, url_prefix='/auth')
api = Blueprint('api', __name__, url_prefix='/api')


# ============================================================
# Auth Routes
# ============================================================

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))

    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data.lower()).first()
        if user and user.check_password(form.password.data):
            login_user(user, remember=(form.remember.data == 'on'))

            next_page = request.args.get('next')
            if next_page and next_page.startswith('/'):
                return redirect(next_page)
            return redirect(url_for('main.dashboard'))
        else:
            flash('電子郵件或密碼錯誤', 'error')

    return render_template('auth/login.html', form=form)


@auth.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('main.dashboard'))

    form = RegisterForm()
    if form.validate_on_submit():
        # Check if email exists
        if User.query.filter_by(email=form.email.data.lower()).first():
            flash('此電子郵件已被註冊', 'error')
            return render_template('auth/register.html', form=form)

        # Create user
        user = User(
            name=form.name.data,
            email=form.email.data.lower()
        )
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()

        flash('註冊成功！請登入', 'success')
        return redirect(url_for('auth.login'))

    return render_template('auth/register.html', form=form)


@auth.route('/logout')
@login_required
def logout():
    logout_user()
    flash('已登出', 'info')
    return redirect(url_for('auth.login'))


# ============================================================
# Main Routes
# ============================================================

@main.route('/')
@login_required
def dashboard():
    today = datetime.today()
    first_day = today.replace(day=1)
    last_day = (first_day + timedelta(days=32)).replace(day=1) - timedelta(days=1)

    # Monthly totals
    income = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'income',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).scalar() or 0

    expense = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).scalar() or 0

    balance = income - expense

    # Recent transactions
    recent = Transaction.query.filter_by(user_id=current_user.id).order_by(
        Transaction.date.desc(), Transaction.created_at.desc()
    ).limit(5).all()

    # Category breakdown for expense chart
    category_breakdown = db.session.query(
        Category.name, Category.color, Category.icon,
        func.sum(Transaction.amount).label('total')
    ).join(Transaction).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).group_by(Category.id).all()

    # Daily expense for bar chart
    daily_expense = db.session.query(
        func.strftime('%d', Transaction.date).label('day'),
        func.sum(Transaction.amount).label('total')
    ).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).group_by('day').all()

    # Build daily data (fill gaps)
    daily_data = {str(i).zfill(2): 0 for i in range(1, last_day.day + 1)}
    for row in daily_expense:
        daily_data[row.day] = row.total
    daily_labels = list(daily_data.keys())
    daily_values = list(daily_data.values())

    chart_income = income
    chart_expense = expense
    chart_balance = balance

    # Convert SQLAlchemy rows to plain dicts for JSON serialization
    categories_data = [
        {'name': c.name, 'color': c.color, 'icon': c.icon, 'total': float(c.total)}
        for c in category_breakdown
    ]

    return render_template('dashboard.html',
                           income=income, expense=expense, balance=balance,
                           recent=recent, chart_income=chart_income,
                           chart_expense=chart_expense, chart_balance=chart_balance,
                           categories=categories_data,
                           daily_labels=daily_labels, daily_values=daily_values,
                           month_name=today.strftime('%Y年%m月'))


@main.route('/transactions')
@login_required
def transactions():
    page = request.args.get('page', 1, type=int)
    per_page = 20
    filters = {}

    # Get filter parameters
    date_from = request.args.get('date_from')
    date_to = request.args.get('date_to')
    type_filter = request.args.get('type')
    category_id = request.args.get('category_id')
    search = request.args.get('search')

    query = Transaction.query.filter_by(user_id=current_user.id)

    if date_from:
        try:
            query = query.filter(Transaction.date >= datetime.strptime(date_from, '%Y-%m-%d').date())
        except ValueError:
            pass

    if date_to:
        try:
            query = query.filter(Transaction.date <= datetime.strptime(date_to, '%Y-%m-%d').date())
        except ValueError:
            pass

    if type_filter in ['income', 'expense']:
        query = query.filter(Transaction.type == type_filter)

    if category_id:
        query = query.filter(Transaction.category_id == category_id)

    if search:
        query = query.filter(Transaction.note.ilike(f'%{search}%'))

    query = query.order_by(Transaction.date.desc(), Transaction.created_at.desc())
    pagination = query.paginate(page=page, per_page=per_page, error_out=False)

    # Get all categories for filter dropdown
    categories = Category.query.filter(
        (Category.user_id == current_user.id) | (Category.is_default == True)
    ).order_by(Category.type, Category.name).all()

    return render_template('transactions.html',
                           transactions=pagination.items,
                           pagination=pagination,
                           categories=categories,
                           filters={'date_from': date_from, 'date_to': date_to,
                                   'type': type_filter, 'category_id': category_id, 'search': search})


@main.route('/categories')
@login_required
def categories():
    user_categories = Category.query.filter_by(user_id=current_user.id).order_by(Category.type, Category.name).all()
    default_categories = Category.query.filter_by(is_default=True).order_by(Category.type, Category.name).all()

    # Combine and deduplicate by name
    all_cats = {}
    for cat in default_categories:
        all_cats[cat.name] = cat
    for cat in user_categories:
        all_cats[cat.name] = cat

    income_cats = [c for c in all_cats.values() if c.type == 'income']
    expense_cats = [c for c in all_cats.values() if c.type == 'expense']

    return render_template('categories.html',
                           income_categories=income_cats,
                           expense_categories=expense_cats)


@main.route('/reports')
@login_required
def reports():
    month_str = request.args.get('month')
    if month_str:
        try:
            year, month = map(int, month_str.split('-'))
            target_date = datetime(year, month, 1)
        except (ValueError, AttributeError):
            target_date = datetime.today().replace(day=1)
    else:
        target_date = datetime.today().replace(day=1)

    first_day = target_date.replace(day=1)
    last_day = (first_day + timedelta(days=32)).replace(day=1) - timedelta(days=1)

    # Monthly totals
    income = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'income',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).scalar() or 0

    expense = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).scalar() or 0

    balance = income - expense

    # Category breakdown
    category_breakdown = db.session.query(
        Category.name, Category.color, Category.icon,
        func.sum(Transaction.amount).label('total')
    ).join(Transaction).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date >= first_day,
        Transaction.date <= last_day
    ).group_by(Category.id).order_by(func.sum(Transaction.amount).desc()).all()

    # Previous month comparison
    prev_first = (first_day - timedelta(days=1)).replace(day=1)
    prev_last = first_day - timedelta(days=1)
    prev_month_str = prev_first.strftime('%Y-%m')
    prev_income = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'income',
        Transaction.date >= prev_first,
        Transaction.date <= prev_last
    ).scalar() or 0
    prev_expense = db.session.query(func.sum(Transaction.amount)).filter(
        Transaction.user_id == current_user.id,
        Transaction.type == 'expense',
        Transaction.date >= prev_first,
        Transaction.date <= prev_last
    ).scalar() or 0

    return render_template('reports.html',
                           income=income, expense=expense, balance=balance,
                           categories=[{'name': c.name, 'color': c.color, 'icon': c.icon, 'total': float(c.total)} for c in category_breakdown],
                           prev_income=prev_income, prev_expense=prev_expense,
                           month_name=target_date.strftime('%Y年%m月'),
                           month_str=target_date.strftime('%Y-%m'),
                           prev_month_str=prev_month_str)


@main.route('/settings', methods=['GET', 'POST'])
@login_required
def settings():
    profile_form = ProfileForm(obj=current_user)
    password_form = PasswordForm()

    if profile_form.submit_profile.data and profile_form.validate_on_submit():
        current_user.name = profile_form.name.data
        db.session.commit()
        flash('個人資料已更新', 'success')
        return redirect(url_for('main.settings'))

    if password_form.submit_password.data and password_form.validate_on_submit():
        if not current_user.check_password(password_form.old_password.data):
            flash('舊密碼錯誤', 'error')
        else:
            current_user.set_password(password_form.new_password.data)
            db.session.commit()
            flash('密碼已更新', 'success')
            return redirect(url_for('main.settings'))

    return render_template('settings.html', profile_form=profile_form, password_form=password_form)


# ============================================================
# API Routes (JSON)
# ============================================================

@api.route('/transactions', methods=['POST'])
@login_required
def create_transaction():
    data = request.get_json()
    current_app.logger.warning(f'[TRANSACTION] POST /api/transactions | user={current_user.id} | data={data}')
    if not data:
        current_app.logger.warning('[TRANSACTION] no JSON data')
        return jsonify({'success': False, 'message': '無效的請求資料'}), 400

    required_fields = ['type', 'amount', 'category_id', 'date']
    for field in required_fields:
        if field not in data or data[field] is None or data[field] == '':
            current_app.logger.warning(f'[TRANSACTION] missing field: {field}')
            return jsonify({'success': False, 'message': f'缺少必要欄位：{field}'}), 400

    if data['type'] not in ('income', 'expense'):
        current_app.logger.warning(f'[TRANSACTION] invalid type: {data.get("type")}')
        return jsonify({'success': False, 'message': '類型必須是收入或支出'}), 400

    try:
        amount = float(data['amount'])
        if amount <= 0:
            current_app.logger.warning(f'[TRANSACTION] invalid amount: {data["amount"]}')
            return jsonify({'success': False, 'message': '金額必須大於 0'}), 400
    except (TypeError, ValueError) as e:
        current_app.logger.warning(f'[TRANSACTION] amount parse error: {data["amount"]} | {e}')
        return jsonify({'success': False, 'message': '金額格式無效'}), 400

    # Verify category belongs to this user (either custom or default)
    cat = Category.query.filter(
        db.or_(
            db.and_(Category.id == data['category_id'], Category.is_default == True),
            db.and_(Category.id == data['category_id'], Category.user_id == current_user.id)
        )
    ).first()
    if not cat:
        current_app.logger.warning(f'[TRANSACTION] category not found: id={data["category_id"]}')
        return jsonify({'success': False, 'message': '無效的分類'}), 400

    try:
        date = datetime.strptime(data['date'], '%Y-%m-%d').date()
    except (ValueError, TypeError) as e:
        current_app.logger.warning(f'[TRANSACTION] date parse error: {data["date"]} | {e}')
        return jsonify({'success': False, 'message': '日期格式無效（需為 YYYY-MM-DD）'}), 400

    trans = Transaction(
        user_id=current_user.id,
        type=data['type'],
        amount=amount,
        category_id=cat.id,
        date=date,
        note=data.get('note') or None
    )
    db.session.add(trans)
    db.session.commit()
    current_app.logger.warning(f'[TRANSACTION] success: type={data["type"]} amount={amount} cat={cat.name}')
    return jsonify({'success': True, 'message': '交易已新增'})


@api.route('/transactions/<int:trans_id>', methods=['PUT'])
@login_required
def update_transaction(trans_id):
    trans = Transaction.query.filter_by(id=trans_id, user_id=current_user.id).first()
    if not trans:
        return jsonify({'success': False, 'message': '找不到交易'}), 404

    data = request.get_json()
    if not data:
        return jsonify({'success': False, 'message': '無效的請求資料'}), 400

    try:
        amount = float(data['amount'])
        if amount <= 0:
            return jsonify({'success': False, 'message': '金額必須大於 0'}), 400
    except (TypeError, ValueError):
        return jsonify({'success': False, 'message': '金額格式無效'}), 400

    try:
        date = datetime.strptime(data['date'], '%Y-%m-%d').date()
    except (ValueError, TypeError):
        return jsonify({'success': False, 'message': '日期格式無效（需為 YYYY-MM-DD）'}), 400

    trans.type = data['type']
    trans.amount = amount
    trans.date = date
    trans.note = data.get('note') or None
    if 'category_id' in data:
        trans.category_id = data['category_id']
    db.session.commit()
    return jsonify({'success': True, 'message': '交易已更新'})


@api.route('/transactions/<int:trans_id>', methods=['DELETE'])
@login_required
def delete_transaction(trans_id):
    trans = Transaction.query.filter_by(id=trans_id, user_id=current_user.id).first()
    if not trans:
        return jsonify({'success': False, 'message': '找不到交易'}), 404

    db.session.delete(trans)
    db.session.commit()
    return jsonify({'success': True, 'message': '交易已刪除'})


@api.route('/categories', methods=['POST'])
@login_required
def create_category():
    form = CategoryForm()
    if form.validate_on_submit():
        cat = Category(
            user_id=current_user.id,
            name=form.name.data,
            icon=form.icon.data or '💰',
            color=form.color.data or '#f59e0b',
            type=request.form.get('type', 'expense'),
            is_default=False
        )
        db.session.add(cat)
        db.session.commit()
        return jsonify({'success': True, 'message': '分類已新增', 'category': {
            'id': cat.id, 'name': cat.name, 'icon': cat.icon, 'color': cat.color, 'type': cat.type
        }})

    return jsonify({'success': False, 'message': form.errors}), 400


@api.route('/categories/<int:cat_id>', methods=['PUT'])
@login_required
def update_category(cat_id):
    cat = Category.query.filter_by(id=cat_id, user_id=current_user.id).filter(Category.is_default == False).first()
    if not cat:
        return jsonify({'success': False, 'message': '找不到分類或無法編輯預設分類'}), 404

    form = CategoryForm()
    if form.validate_on_submit():
        cat.name = form.name.data
        cat.icon = form.icon.data or '💰'
        cat.color = form.color.data or '#f59e0b'
        db.session.commit()
        return jsonify({'success': True, 'message': '分類已更新'})

    return jsonify({'success': False, 'message': form.errors}), 400


@api.route('/categories/list', methods=['GET'])
@login_required
def list_categories():
    all_cats = Category.query.filter(
        db.or_(
            db.and_(
                Category.user_id.is_(None),
                Category.is_default == True
            ),
            db.and_(
                Category.user_id == current_user.id,
                Category.is_default == False
            )
        )
    ).order_by(Category.type, Category.name).all()
    return jsonify({
        'income': [{'id': c.id, 'name': c.name, 'icon': c.icon, 'color': c.color} for c in all_cats if c.type == 'income'],
        'expense': [{'id': c.id, 'name': c.name, 'icon': c.icon, 'color': c.color} for c in all_cats if c.type == 'expense'],
    })


@api.route('/categories/<int:cat_id>', methods=['DELETE'])
@login_required
def delete_category(cat_id):
    cat = Category.query.filter_by(id=cat_id, user_id=current_user.id).filter(Category.is_default == False).first()
    if not cat:
        return jsonify({'success': False, 'message': '找不到分類或無法刪除預設分類'}), 404

    # Transfer transactions to "其他" category
    other_cat = Category.query.filter_by(user_id=current_user.id, name='其他支出' if cat.type == 'expense' else '其他收入').first()
    if other_cat:
        Transaction.query.filter_by(category_id=cat.id).update({'category_id': other_cat.id})

    db.session.delete(cat)
    db.session.commit()
    return jsonify({'success': True, 'message': '分類已刪除'})