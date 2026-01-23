from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base


# SQLite DB file in backend folder
SQLALCHEMY_DATABASE_URL = "sqlite:///./mediscan.db"


engine = create_engine(
    SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False}
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

from . import models
models.Base.metadata.create_all(bind=engine)