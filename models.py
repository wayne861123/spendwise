from flask_sqlalchemy import SQLAlchemy
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from datetime import datetime

db = SQLAlchemy()


class User(UserMixin, db.Model):
    __tablename__ = 'users'

    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    transactions = db.relationship('Transaction', backref='user', lazy=True, cascade='all, delete-orphan')
    categories = db.relationship('Category', backref='user', lazy=True, cascade='all, delete-orphan')

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

    def get_id(self):
        return str(self.id)


class Category(db.Model):
    __tablename__ = 'categories'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)  # null = default
    name = db.Column(db.String(50), nullable=False)
    icon = db.Column(db.String(10), default='💰')
    color = db.Column(db.String(7), default='#f59e0b')
    type = db.Column(db.String(10), nullable=False)  # 'income' or 'expense'
    is_default = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)

    transactions = db.relationship('Transaction', backref='category', lazy=True)

    @staticmethod
    def get_defaults():
        return [
            {'name': '薪水', 'icon': '💵', 'color': '#10b981', 'type': 'income'},
            {'name': '獎金', 'icon': '🎁', 'color': '#f59e0b', 'type': 'income'},
            {'name': '投資收益', 'icon': '📈', 'color': '#3b82f6', 'type': 'income'},
            {'name': '其他收入', 'icon': '💰', 'color': '#8b5cf6', 'type': 'income'},
            {'name': '餐飲', 'icon': '🍜', 'color': '#ef4444', 'type': 'expense'},
            {'name': '交通', 'icon': '🚗', 'color': '#3b82f6', 'type': 'expense'},
            {'name': '娛樂', 'icon': '🎮', 'color': '#8b5cf6', 'type': 'expense'},
            {'name': '購物', 'icon': '🛒', 'color': '#f59e0b', 'type': 'expense'},
            {'name': '醫療', 'icon': '🏥', 'color': '#ef4444', 'type': 'expense'},
            {'name': '居住', 'icon': '🏠', 'color': '#10b981', 'type': 'expense'},
            {'name': '通訊', 'icon': '📱', 'color': '#06b6d4', 'type': 'expense'},
            {'name': '其他支出', 'icon': '📦', 'color': '#64748b', 'type': 'expense'},
        ]


class Transaction(db.Model):
    __tablename__ = 'transactions'

    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    type = db.Column(db.String(10), nullable=False)  # 'income' or 'expense'
    amount = db.Column(db.Float, nullable=False)
    category_id = db.Column(db.Integer, db.ForeignKey('categories.id'), nullable=False)
    date = db.Column(db.Date, nullable=False)
    note = db.Column(db.String(255), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)