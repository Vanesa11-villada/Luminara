package domain

import (
	"database/sql"
	"time"
)

type User struct {
	ID            uint64
	Nombre        string
	Apellido      sql.NullString
	Email         string
	PasswordHash  string
	RolID         uint8
	Activo        bool
	CreadoEn      time.Time
	ActualizadoEn time.Time
}
