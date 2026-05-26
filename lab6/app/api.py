from typing import Literal
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, text, or_, asc, desc
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import (
    get_db,
    Employee,
    Dogovors,
    Vacation,
    WorkTime,
)
from app.models import (
    EmployeeCreate,
    EmployeeUpdate,
    EmployeeRead,
    DogovorCreate,
    DogovorUpdate,
    DogovorRead,
    VacationCreate,
    VacationUpdate,
    VacationRead,
    WorkTimeCreate,
    WorkTimeUpdate,
    WorkTimeRead,
    AddWorktimeEntryRequest,
    UpdateSalaryRequest,
)

router = APIRouter()


def apply_list_params(
    stmt,
    model,
    allowed_sort_fields: set[str],
    filter_value: str | None,
    filter_fields: list,
    sort: str,
    order: Literal["asc", "desc"],
    page: int,
    limit: int,
):
    if filter_value:
        stmt = stmt.where(
            or_(*[field.ilike(f"%{filter_value}%") for field in filter_fields])
        )

    if sort not in allowed_sort_fields:
        raise HTTPException(
            status_code=400,
            detail=f"Сортировка по полю '{sort}' не разрешена",
        )

    sort_column = getattr(model, sort)

    if order == "desc":
        stmt = stmt.order_by(desc(sort_column))
    else:
        stmt = stmt.order_by(asc(sort_column))

    offset = (page - 1) * limit
    return stmt.offset(offset).limit(limit)


async def commit_or_rollback(db: AsyncSession):
    try:
        await db.commit()
    except IntegrityError as e:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка ограничения БД: {str(e.orig)}",
        )
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(
            status_code=500,
            detail=f"Ошибка базы данных: {str(e)}",
        )


async def get_object_or_404(db: AsyncSession, model, pk_field, pk_value):
    result = await db.execute(select(model).where(pk_field == pk_value))
    obj = result.scalar_one_or_none()
    if obj is None:
        raise HTTPException(status_code=404, detail="Запись не найдена")
    return obj


@router.get("/ping")
async def ping():
    return {"ping": "pong"}


# ---------- Employee CRUD ----------

@router.get("/employees", response_model=list[EmployeeRead])
async def get_employees(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "employee_id",
    order: Literal["asc", "desc"] = "asc",
    filter: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Employee)
    stmt = apply_list_params(
        stmt=stmt,
        model=Employee,
        allowed_sort_fields={"employee_id", "first_name", "last_name", "birth_date"},
        filter_value=filter,
        filter_fields=[Employee.first_name, Employee.last_name],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/employees/{employee_id}", response_model=EmployeeRead)
async def get_employee(employee_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, Employee, Employee.employee_id, employee_id)


@router.post("/employees", response_model=EmployeeRead, status_code=201)
async def create_employee(data: EmployeeCreate, db: AsyncSession = Depends(get_db)):
    emp = Employee(**data.model_dump())
    db.add(emp)
    await commit_or_rollback(db)
    await db.refresh(emp)
    return emp


@router.put("/employees/{employee_id}", response_model=EmployeeRead)
async def update_employee(
    employee_id: int,
    data: EmployeeUpdate,
    db: AsyncSession = Depends(get_db),
):
    emp = await get_object_or_404(db, Employee, Employee.employee_id, employee_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(emp, key, value)
    await commit_or_rollback(db)
    await db.refresh(emp)
    return emp


@router.delete("/employees/{employee_id}")
async def delete_employee(employee_id: int, db: AsyncSession = Depends(get_db)):
    emp = await get_object_or_404(db, Employee, Employee.employee_id, employee_id)
    await db.delete(emp)
    await commit_or_rollback(db)
    return {"message": "Сотрудник удален"}


# ---------- Dogovors CRUD ----------

@router.get("/dogovors", response_model=list[DogovorRead])
async def get_dogovors(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "dogovor_id",
    order: Literal["asc", "desc"] = "asc",
    filter: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Dogovors)
    stmt = apply_list_params(
        stmt=stmt,
        model=Dogovors,
        allowed_sort_fields={
            "dogovor_id",
            "employee_id",
            "position",
            "salary",
            "department",
            "start_date",
        },
        filter_value=filter,
        filter_fields=[Dogovors.position, Dogovors.department],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/dogovors/{dogovor_id}", response_model=DogovorRead)
async def get_dogovor(dogovor_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, Dogovors, Dogovors.dogovor_id, dogovor_id)


@router.post("/dogovors", response_model=DogovorRead, status_code=201)
async def create_dogovor(data: DogovorCreate, db: AsyncSession = Depends(get_db)):
    d = Dogovors(**data.model_dump())
    db.add(d)
    await commit_or_rollback(db)
    await db.refresh(d)
    return d


@router.put("/dogovors/{dogovor_id}", response_model=DogovorRead)
async def update_dogovor(
    dogovor_id: int,
    data: DogovorUpdate,
    db: AsyncSession = Depends(get_db),
):
    d = await get_object_or_404(db, Dogovors, Dogovors.dogovor_id, dogovor_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(d, key, value)
    await commit_or_rollback(db)
    await db.refresh(d)
    return d


@router.delete("/dogovors/{dogovor_id}")
async def delete_dogovor(dogovor_id: int, db: AsyncSession = Depends(get_db)):
    d = await get_object_or_404(db, Dogovors, Dogovors.dogovor_id, dogovor_id)
    await db.delete(d)
    await commit_or_rollback(db)
    return {"message": "Договор удален"}


# ---------- Vacation CRUD ----------

@router.get("/vacations", response_model=list[VacationRead])
async def get_vacations(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "vacation_id",
    order: Literal["asc", "desc"] = "asc",
    filter: str | None = None,
    db: AsyncSession = Depends(get_db),
):
    stmt = select(Vacation)
    stmt = apply_list_params(
        stmt=stmt,
        model=Vacation,
        allowed_sort_fields={
            "vacation_id",
            "employee_id",
            "start_date",
            "end_date",
            "type",
        },
        filter_value=filter,
        filter_fields=[Vacation.type],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/vacations/{vacation_id}", response_model=VacationRead)
async def get_vacation(vacation_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, Vacation, Vacation.vacation_id, vacation_id)


@router.post("/vacations", response_model=VacationRead, status_code=201)
async def create_vacation(data: VacationCreate, db: AsyncSession = Depends(get_db)):
    v = Vacation(**data.model_dump())
    db.add(v)
    await commit_or_rollback(db)
    await db.refresh(v)
    return v


@router.put("/vacations/{vacation_id}", response_model=VacationRead)
async def update_vacation(
    vacation_id: int,
    data: VacationUpdate,
    db: AsyncSession = Depends(get_db),
):
    v = await get_object_or_404(db, Vacation, Vacation.vacation_id, vacation_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(v, key, value)
    await commit_or_rollback(db)
    await db.refresh(v)
    return v


@router.delete("/vacations/{vacation_id}")
async def delete_vacation(vacation_id: int, db: AsyncSession = Depends(get_db)):
    v = await get_object_or_404(db, Vacation, Vacation.vacation_id, vacation_id)
    await db.delete(v)
    await commit_or_rollback(db)
    return {"message": "Отпуск удален"}


# ---------- WorkTime CRUD ----------

@router.get("/worktime", response_model=list[WorkTimeRead])
async def get_worktime(
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "worktime_id",
    order: Literal["asc", "desc"] = "asc",
    db: AsyncSession = Depends(get_db),
):
    stmt = select(WorkTime)
    stmt = apply_list_params(
        stmt=stmt,
        model=WorkTime,
        allowed_sort_fields={
            "worktime_id",
            "employee_id",
            "work_date",
            "hours_worked",
        },
        filter_value=None,
        filter_fields=[],
        sort=sort,
        order=order,
        page=page,
        limit=limit,
    )
    result = await db.execute(stmt)
    return result.scalars().all()


@router.get("/worktime/{worktime_id}", response_model=WorkTimeRead)
async def get_worktime_entry(worktime_id: int, db: AsyncSession = Depends(get_db)):
    return await get_object_or_404(db, WorkTime, WorkTime.worktime_id, worktime_id)


@router.post("/worktime", response_model=WorkTimeRead, status_code=201)
async def create_worktime(data: WorkTimeCreate, db: AsyncSession = Depends(get_db)):
    w = WorkTime(**data.model_dump())
    db.add(w)
    await commit_or_rollback(db)
    await db.refresh(w)
    return w


@router.put("/worktime/{worktime_id}", response_model=WorkTimeRead)
async def update_worktime(
    worktime_id: int,
    data: WorkTimeUpdate,
    db: AsyncSession = Depends(get_db),
):
    w = await get_object_or_404(db, WorkTime, WorkTime.worktime_id, worktime_id)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(w, key, value)
    await commit_or_rollback(db)
    await db.refresh(w)
    return w


@router.delete("/worktime/{worktime_id}")
async def delete_worktime(worktime_id: int, db: AsyncSession = Depends(get_db)):
    w = await get_object_or_404(db, WorkTime, WorkTime.worktime_id, worktime_id)
    await db.delete(w)
    await commit_or_rollback(db)
    return {"message": "Запись рабочего времени удалена"}


# ---------- Views ----------

@router.get("/views/department-stats")
async def get_department_stats(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT *
            FROM view_department_stats
            ORDER BY department
        """)
    )
    return [dict(row._mapping) for row in result.fetchall()]


@router.get("/views/employee-hours-summary")
async def get_employee_hours_summary(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT *
            FROM view_employee_hours_summary
            ORDER BY employee_id
        """)
    )
    return [dict(row._mapping) for row in result.fetchall()]


# ---------- Functions ----------

@router.get("/employees/{employee_id}/age")
async def get_employee_age(employee_id: int, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            text("SELECT fn_get_employee_age(:emp_id) AS age"),
            {"emp_id": employee_id},
        )
        row = result.fetchone()
        return {"employee_id": employee_id, "age": row.age}
    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове fn_get_employee_age: {str(e)}",
        )


@router.get("/employees/{employee_id}/total-hours")
async def get_employee_total_hours(employee_id: int, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(
            text("SELECT fn_get_total_hours(:emp_id) AS total_hours"),
            {"emp_id": employee_id},
        )
        row = result.fetchone()
        return {"employee_id": employee_id, "total_hours": row.total_hours}
    except SQLAlchemyError as e:
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове fn_get_total_hours: {str(e)}",
        )


# ---------- Procedures ----------

@router.post("/worktime/add-entry")
async def add_worktime_entry(
    data: AddWorktimeEntryRequest,
    db: AsyncSession = Depends(get_db),
):
    try:
        await db.execute(
            text("""
                CALL pr_add_worktime_entry(
                    :emp_id,
                    :work_date,
                    :hours
                )
            """),
            {
                "emp_id": data.employee_id,
                "work_date": data.work_date,
                "hours": data.hours,
            },
        )
        await db.commit()
        return {
            "message": "Запись рабочего времени добавлена",
            "employee_id": data.employee_id,
            "work_date": data.work_date,
            "hours": data.hours,
        }
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове pr_add_worktime_entry: {str(e)}",
        )


@router.post("/dogovors/update-salary")
async def update_salary(
    data: UpdateSalaryRequest,
    db: AsyncSession = Depends(get_db),
):
    try:
        await db.execute(
            text("""
                CALL pr_update_salary(
                    :emp_id,
                    :amount
                )
            """),
            {
                "emp_id": data.employee_id,
                "amount": data.amount,
            },
        )
        await db.commit()
        return {
            "message": "Зарплата обновлена",
            "employee_id": data.employee_id,
            "amount": data.amount,
        }
    except SQLAlchemyError as e:
        await db.rollback()
        raise HTTPException(
            status_code=400,
            detail=f"Ошибка при вызове pr_update_salary: {str(e)}",
        )


# ---------- Reports ----------

@router.get("/reports/salary-by-department")
async def report_salary_by_department(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        text("""
            SELECT
                department,
                employees_count,
                avg_salary
            FROM view_department_stats
            ORDER BY department
        """)
    )
    return [dict(row._mapping) for row in result.fetchall()]


@router.get("/reports/top-employees-by-hours")
async def report_top_employees_by_hours(
    limit: int = Query(10, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        text("""
            SELECT
                employee_id,
                first_name,
                last_name,
                total_hours,
                avg_hours_worked_per_day
            FROM view_employee_hours_summary
            ORDER BY total_hours DESC
            LIMIT :limit
        """),
        {"limit": limit},
    )
    return [dict(row._mapping) for row in result.fetchall()]
