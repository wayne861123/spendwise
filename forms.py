from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, DateField, FloatField, SelectField, TextAreaField, SubmitField
from wtforms.validators import DataRequired, Email, Length, EqualTo, ValidationError, NumberRange, Optional
import re


class RegisterForm(FlaskForm):
    name = StringField('姓名', validators=[
        DataRequired(message='請輸入姓名'),
        Length(min=2, max=50, message='姓名長度需在 2-50 個字之間')
    ])
    email = StringField('電子郵件', validators=[
        DataRequired(message='請輸入電子郵件'),
        Email(message='請輸入有效的電子郵件格式')
    ])
    password = PasswordField('密碼', validators=[
        DataRequired(message='請輸入密碼'),
        Length(min=8, message='密碼至少需要 8 個字元'),
    ])
    confirm_password = PasswordField('確認密碼', validators=[
        DataRequired(message='請再次輸入密碼'),
        EqualTo('password', message='兩次輸入的密碼不一致')
    ])
    submit = SubmitField('註冊')

    def validate_password(self, field):
        password = field.data
        if not re.search(r'[0-9]', password):
            raise ValidationError('密碼需包含至少一個數字')
        if not re.search(r'[^a-zA-Z0-9]', password):
            raise ValidationError('密碼需包含至少一個特殊符號')
        if len(password) < 8:
            raise ValidationError('密碼至少需要 8 個字元')


class LoginForm(FlaskForm):
    email = StringField('電子郵件', validators=[
        DataRequired(message='請輸入電子郵件'),
        Email(message='請輸入有效的電子郵件格式')
    ])
    password = PasswordField('密碼', validators=[
        DataRequired(message='請輸入密碼')
    ])
    remember = SelectField('記住我', choices=[('on', '記住我')], default='off')
    submit = SubmitField('登入')


class TransactionForm(FlaskForm):
    type = SelectField('類型', choices=[('income', '收入'), ('expense', '支出')], validators=[DataRequired()])
    amount = FloatField('金額', validators=[
        DataRequired(message='請輸入金額'),
        NumberRange(min=0.01, message='金額需大於 0')
    ])
    category_id = SelectField('分類', coerce=int, validators=[DataRequired(message='請選擇分類')])
    date = DateField('日期', format='%Y-%m-%d', validators=[DataRequired(message='請選擇日期')])
    note = StringField('備註', validators=[Optional(), Length(max=255)])
    submit = SubmitField('儲存')


class CategoryForm(FlaskForm):
    name = StringField('分類名稱', validators=[
        DataRequired(message='請輸入分類名稱'),
        Length(min=1, max=50, message='分類名稱長度需在 1-50 個字之間')
    ])
    icon = StringField('圖示', validators=[Optional(), Length(max=10)], default='💰')
    color = StringField('顏色', validators=[Optional(), Length(min=7, max=7)], default='#f59e0b')
    submit = SubmitField('儲存')


class ProfileForm(FlaskForm):
    name = StringField('姓名', validators=[
        DataRequired(message='請輸入姓名'),
        Length(min=2, max=50, message='姓名長度需在 2-50 個字之間')
    ])
    submit_profile = SubmitField('儲存變更')


class PasswordForm(FlaskForm):
    old_password = PasswordField('舊密碼', validators=[DataRequired(message='請輸入舊密碼')])
    new_password = PasswordField('新密碼', validators=[
        DataRequired(message='請輸入新密碼'),
        Length(min=8, message='密碼至少需要 8 個字元'),
    ])
    confirm_password = PasswordField('確認新密碼', validators=[
        DataRequired(message='請再次輸入新密碼'),
        EqualTo('new_password', message='兩次輸入的密碼不一致')
    ])
    submit_password = SubmitField('更新密碼')

    def validate_new_password(self, field):
        password = field.data
        if not re.search(r'[0-9]', password):
            raise ValidationError('密碼需包含至少一個數字')