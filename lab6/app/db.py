import os
from decimal import Decimal
from datetime import date

from sqlalchemy import (
    MetaData,
    String,
    Integer,
    Date,
    Numeric,
    ForeignKey,
    CheckConstraint,
)
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

DATABASE_URL = os.getenv("DATABASE_URL")

engine = create_async_engine(DATABASE_URL)
async_session = async_sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)
metadata = MetaData()


async def get_db():
    async with async_session() as session:
        yield session


class Base(DeclarativeBase):
    pass


class Employee(Base):
    __tablename__ = "Employee"

    employee_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    first_name: Mapped[str] = mapped_column(String(50), nullable=False)
    last_name: Mapped[str] = mapped_column(String(50), nullable=False)
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)

    dogovors: Mapped[list["Dogovors"]] = relationship(
        back_populates="employee",
        cascade="all, delete-orphan",
    )
    vacations: Mapped[list["Vacation"]] = relationship(
        back_populates="employee",
        cascade="all, delete-orphan",
    )
    worktime_entries: Mapped[list["WorkTime"]] = relationship(
        back_populates="employee",
        cascade="all, delete-orphan",
    )


class Dogovors(Base):
    __tablename__ = "Dogovors"

    dogovor_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    position: Mapped[str] = mapped_column(String(100), nullable=False)
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    salary: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    department: Mapped[str] = mapped_column(String(100), nullable=False)

    employee_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("Employee.employee_id", ondelete="CASCADE"),
        nullable=False,
    )

    employee: Mapped["Employee"] = relationship(back_populates="dogovors")

    __table_args__ = (
        CheckConstraint("salary > 0", name="check_salary_positive"),
    )


class Vacation(Base):
    __tablename__ = "Vacation"

    vacation_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    employee_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("Employee.employee_id", ondelete="CASCADE"),
        nullable=False,
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    type: Mapped[str | None] = mapped_column(String(50), nullable=True)

    employee: Mapped["Employee"] = relationship(back_populates="vacations")


class WorkTime(Base):
    __tablename__ = "WorkTime"

    worktime_id: Mapped[int] = mapped_column(Integer, primary_key=True)
    employee_id: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("Employee.employee_id", ondelete="CASCADE"),
        nullable=False,
    )
    work_date: Mapped[date] = mapped_column(Date, nullable=False)
    hours_worked: Mapped[Decimal] = mapped_column(Numeric(4, 2), nullable=False)

    employee: Mapped["Employee"] = relationship(back_populates="worktime_entries")

    __table_args__ = (
        CheckConstraint("hours_worked >= 0", name="check_hours_non_negative"),
        CheckConstraint("hours_worked <= 24", name="check_hours_max_24"),
    )
