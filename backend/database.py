import os
from sqlmodel import SQLModel, create_engine, Session

# Get database path from environment, default to /app/data/database.db for production
DB_PATH = os.getenv("DATABASE_PATH", "/app/data/database.db")
DATABASE_URL = f"sqlite:///{DB_PATH}"

connect_args = {"check_same_thread": False}
engine = create_engine(DATABASE_URL, connect_args=connect_args)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
