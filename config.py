import os

basedir = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))


class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'

    # Use /data on Render (persistent disk), otherwise local instance folder
    if os.environ.get('RENDER'):
        SQLALCHEMY_DATABASE_URI = 'sqlite:////data/spendwise.db'
    else:
        db_path = os.path.join(basedir, 'instance', 'spendwise.db')
        os.makedirs(os.path.join(basedir, 'instance'), exist_ok=True)
        SQLALCHEMY_DATABASE_URI = 'sqlite:///' + db_path

    SQLALCHEMY_TRACK_MODIFICATIONS = False
    PERMANENT_SESSION_LIFETIME = 60 * 60 * 24 * 7  # 7 days
    SESSION_COOKIE_SECURE = False  # Set True in production with HTTPS
    SESSION_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'