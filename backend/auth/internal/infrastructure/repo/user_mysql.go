package repo

import (
	"context"
	"database/sql"
	"errors"
	"time"

	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/domain"
)

type UserMySQLRepository struct {
	db *sql.DB
}

func NewUserMySQLRepository(db *sql.DB) *UserMySQLRepository {
	return &UserMySQLRepository{db: db}
}

func (r *UserMySQLRepository) Create(ctx context.Context, u domain.User) (uint64, error) {
	q := `
		INSERT INTO usuario (nombre, apellido, email, password_hash, rol_id, activo)
		VALUES (?, ?, ?, ?, ?, ?)
	`
	res, err := r.db.ExecContext(ctx, q,
		u.Nombre,
		u.Apellido,
		u.Email,
		u.PasswordHash,
		u.RolID,
		u.Activo,
	)
	if err != nil {
		return 0, err
	}
	id, err := res.LastInsertId()
	return uint64(id), err
}

func (r *UserMySQLRepository) GetByID(ctx context.Context, id uint64) (*domain.User, error) {
	q := `
		SELECT id, nombre, apellido, email, password_hash, rol_id, activo,
		       creado_en, actualizado_en, last_login_at, inactivated_at, inactivated_reason
		FROM usuario
		WHERE id = ?
		LIMIT 1
	`
	var u domain.User
	err := r.db.QueryRowContext(ctx, q, id).Scan(
		&u.ID, &u.Nombre, &u.Apellido, &u.Email, &u.PasswordHash, &u.RolID, &u.Activo,
		&u.CreadoEn, &u.ActualizadoEn, &u.LastLoginAt, &u.InactivatedAt, &u.InactivatedReason,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return &u, nil
}

func (r *UserMySQLRepository) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	q := `
		SELECT id, nombre, apellido, email, password_hash, rol_id, activo,
		       creado_en, actualizado_en, last_login_at, inactivated_at, inactivated_reason
		FROM usuario
		WHERE email = ?
		LIMIT 1
	`
	var u domain.User
	err := r.db.QueryRowContext(ctx, q, email).Scan(
		&u.ID, &u.Nombre, &u.Apellido, &u.Email, &u.PasswordHash, &u.RolID, &u.Activo,
		&u.CreadoEn, &u.ActualizadoEn, &u.LastLoginAt, &u.InactivatedAt, &u.InactivatedReason,
	)
	if err != nil {
		if errors.Is(err, sql.ErrNoRows) {
			return nil, nil
		}
		return nil, err
	}
	return &u, nil
}

func (r *UserMySQLRepository) List(ctx context.Context, limit, offset int) ([]domain.User, error) {
	if limit <= 0 || limit > 200 {
		limit = 50
	}
	if offset < 0 {
		offset = 0
	}

	q := `
		SELECT id, nombre, apellido, email, password_hash, rol_id, activo,
		       creado_en, actualizado_en, last_login_at, inactivated_at, inactivated_reason
		FROM usuario
		ORDER BY id DESC
		LIMIT ? OFFSET ?
	`
	rows, err := r.db.QueryContext(ctx, q, limit, offset)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []domain.User
	for rows.Next() {
		var u domain.User
		if err := rows.Scan(
			&u.ID, &u.Nombre, &u.Apellido, &u.Email, &u.PasswordHash, &u.RolID, &u.Activo,
			&u.CreadoEn, &u.ActualizadoEn, &u.LastLoginAt, &u.InactivatedAt, &u.InactivatedReason,
		); err != nil {
			return nil, err
		}
		out = append(out, u)
	}
	return out, rows.Err()
}

func (r *UserMySQLRepository) Update(ctx context.Context, u domain.User) error {
	q := `
		UPDATE usuario
		SET nombre = ?, apellido = ?, rol_id = ?, activo = ?
		WHERE id = ?
	`
	_, err := r.db.ExecContext(ctx, q,
		u.Nombre,
		u.Apellido,
		u.RolID,
		u.Activo,
		u.ID,
	)
	return err
}

func (r *UserMySQLRepository) Deactivate(ctx context.Context, id uint64, reason string) error {
	if reason == "" {
		reason = "INACTIVIDAD"
	}
	now := time.Now()

	q := `
		UPDATE usuario
		SET activo = FALSE,
		    inactivated_at = ?,
		    inactivated_reason = ?
		WHERE id = ?
	`
	_, err := r.db.ExecContext(ctx, q, now, reason, id)
	return err
}
