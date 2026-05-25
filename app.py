import os
import sqlite3
from datetime import datetime
from flask import Flask, request
from flask_login import LoginManager
from config import Config
from models import db, User, Category

from flask_wtf.csrf import CSRFProtect

login_manager = LoginManager()
csrf = CSRFProtect()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Log all requests (including failed ones) for debugging
    @app.before_request
    def log_request():
        pass

    @app.after_request
    def log_response(response):
        if request.path.startswith('/api/'):
            print(f'[DEBUG] {request.method} {request.path} -> {response.status_code} | data={request.get_json(silent=True)}')
        return response

    # Global error handler for CSRF
    @app.errorhandler(400)
    def handle_csrf_error(e):
        print(f'[CSRF ERROR] 400 on {request.path} | desc={e.description}')
        from flask import jsonify, request
        if request.path.startswith('/api/'):
            return jsonify({'success': False, 'message': e.description or 'CSRF驗證失敗'}), 400
        from flask import render_template
        from flask_login import current_user
        if current_user.is_authenticated:
            return render_template('dashboard.html'), 400
        return e

    # Initialize extensions
    db.init_app(app)
    login_manager.init_app(app)
    csrf.init_app(app)

    # Register blueprints
    from routes import main, auth, api
    app.register_blueprint(main)
    app.register_blueprint(auth)
    app.register_blueprint(api)

    # Disable CSRF protection for API blueprint (we use X-CSRFToken header instead)
    csrf.exempt(api)

    login_manager.login_view = 'auth.login'
    login_manager.login_message = '請先登入'

    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    # Create database and default categories
    with app.app_context():
        db.create_all()

        # Seed default categories if none exist
        if Category.query.filter_by(is_default=True).first() is None:
            defaults = Category.get_defaults()
            for cat_data in defaults:
                cat = Category(is_default=True, **cat_data)
                db.session.add(cat)
            db.session.commit()

    return app


if __name__ == '__main__':
    app = create_app()
    app.run(debug=True, host='0.0.0.0', port=5000)
else:
    # Expose app for gunicorn / WSGI servers
    app = create_app()