from decimal import Decimal
from datetime import date
from pydantic import BaseModel, ConfigDict, Field


class EmployeeBase(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=50)
    last_name: str = Field(..., min_length=1, max_length=50)
    birth_date: date | None = None


class EmployeeCreate(EmployeeBase):
    employee_id: int


class EmployeeUpdate(BaseModel):
    first_name: str | None = Field(None, min_length=1, max_length=50)
    last_name: str | None = Field(None, min_length=1, max_length=50)
    birth_date: date | None = None


class EmployeeRead(EmployeeBase):
    model_config = ConfigDict(from_attributes=True)
    employee_id: int


class DogovorBase(BaseModel):
    position: str = Field(..., min_length=1, max_length=100)
    start_date: date
    end_date: date | None = None
    salary: Decimal = Field(..., gt=0)
    department: str = Field(..., min_length=1, max_length=100)
    employee_id: int


class DogovorCreate(DogovorBase):
    dogovor_id: int


class DogovorUpdate(BaseModel):
    position: str | None = Field(None, min_length=1, max_length=100)
    start_date: date | None = None
    end_date: date | None = None
    salary: Decimal | None = Field(None, gt=0)
    department: str | None = Field(None, min_length=1, max_length=100)
    employee_id: int | None = None


class DogovorRead(DogovorBase):
    model_config = ConfigDict(from_attributes=True)
    dogovor_id: int


class VacationBase(BaseModel):
    employee_id: int
    start_date: date
    end_date: date
    type: str | None = Field(None, max_length=50)


class VacationCreate(VacationBase):
    vacation_id: int


class VacationUpdate(BaseModel):
    employee_id: int | None = None
    start_date: date | None = None
    end_date: date | None = None
    type: str | None = Field(None, max_length=50)


class VacationRead(VacationBase):
    model_config = ConfigDict(from_attributes=True)
    vacation_id: int


class WorkTimeBase(BaseModel):
    employee_id: int
    work_date: date
    hours_worked: Decimal = Field(..., ge=0, le=24)


class WorkTimeCreate(WorkTimeBase):
    worktime_id: int


class WorkTimeUpdate(BaseModel):
    employee_id: int | None = None
    work_date: date | None = None
    hours_worked: Decimal | None = Field(None, ge=0, le=24)


class WorkTimeRead(WorkTimeBase):
    model_config = ConfigDict(from_attributes=True)
    worktime_id: int


class AddWorktimeEntryRequest(BaseModel):
    employee_id: int
    work_date: date
    hours: Decimal = Field(..., gt=0, le=24)


class UpdateSalaryRequest(BaseModel):
    employee_id: int
    amount: Decimal
