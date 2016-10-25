import os
from celery import Celery
from app import app as flask_app


def make_celery(app):
    celery = Celery(
        'fakery',
        backend=os.environ['REDISTOGO_URL'],
        broker=os.environ['REDISTOGO_URL']
    )

    celery.conf.update(
        CELERY_ENABLE_UTC=True,
        CELERY_TIMEZONE='America/New_York'
    )
    TaskBase = celery.Task

    class ContextTask(TaskBase):
        abstract = True

        def __call__(self, *args, **kwargs):
            # with app.app_context():
            return TaskBase.__call__(self, *args, **kwargs)

    celery.Task = ContextTask
    return celery


celery = make_celery(flask_app)


@celery.task
def add_together(a, b):
    return a + b


@celery.task
def multiply(a, b):
    return a * b
