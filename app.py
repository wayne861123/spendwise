import os
import sqlite3
from datetime import datetime
from flask import Flask
from flask_login import LoginManager
from config import Config
from models import db, User, Category

login_manager = LoginManager()


def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    # Initialize extensions
    db.init_app(app)
    login_manager.init_app(app)
    login_manager.login_view = 'auth.login'
    login_manager.login_message = '請先登入'

    @login_manager.user_loader
    def load_user(user_id):
        return User.query.get(int(user_id))

    # Register blueprints
    from routes import main, auth, api
    app.register_blueprint(main)
    app.register_blueprint(auth)
    app.register_blueprint(api)

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