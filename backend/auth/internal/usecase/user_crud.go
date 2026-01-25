package usecase

import (
	"context"
	"database/sql"
	"errors"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"

	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/domain"
	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/ports"
)

var (
	ErrEmailInvalido   = errors.New("email inválido")
	ErrPasswordInvalida = errors.New("password inválida")
	ErrUsuarioNoExiste = errors.New("usuario no existe")
)

type UserCRUD struct {
	repo ports.UserRepository
}

func NewUserCRUD(repo ports.UserRepository) *UserCRUD {
	return &UserCRUD{repo: repo}
}

type CreateUserInput struct {
	Nombre   string
	Apellido string
	Email    string
	Password string
	RolID    uint8
}

func (uc *UserCRUD) Create(ctx context.Context, in CreateUserInput) (uint64, error) {
	email := strings.TrimSpace(strings.ToLower(in.Email))
	if !strings.Contains(email, "@") {
		return 0, ErrEmailInvalido
	}
	if len(in.Password) < 8 {
		return 0, ErrPasswordInvalida
	}
	if in.RolID == 0 {
		in.RolID = 1 // Cliente por defecto
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), bcrypt.DefaultCost)
	if err != nil {
		return 0, err
	}

	u := domain.User{
		Nombre:       strings.TrimSpace(in.Nombre),
		Apellido:     sql.NullString{String: strings.TrimSpace(in.Apellido), Valid: strings.TrimSpace(in.Apellido) != ""},
		Email:        email,
		PasswordHash: string(hash),
		RolID:        in.RolID,
		Activo:       true,
	}

	ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
	defer cancel()

	return uc.repo.Create(ctx, u)
}

func (uc *UserCRUD) GetByID(ctx context.Context, id uint64) (*domain.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
	defer cancel()

	u, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return nil, err
	}
	if u == nil {
		return nil, ErrUsuarioNoExiste
	}
	return u, nil
}

func (uc *UserCRUD) GetByEmail(ctx context.Context, email string) (*domain.User, error) {
	email = strings.TrimSpace(strings.ToLower(email))

	ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
	defer cancel()

	u, err := uc.repo.GetByEmail(ctx, email)
	if err != nil {
		return nil, err
	}
	if u == nil {
		return nil, ErrUsuarioNoExiste
	}
	return u, nil
}

func (uc *UserCRUD) List(ctx context.Context, limit, offset int) ([]domain.User, error) {
	ctx, cancel := context.WithTimeout(ctx, 6*time.Second)
	defer cancel()

	return uc.repo.List(ctx, limit, offset)
}

type UpdateUserInput struct {
	Nombre   string
	Apellido string
	RolID    uint8
	Activo   bool
}

func (uc *UserCRUD) Update(ctx context.Context, id uint64, in UpdateUserInput) error {
	ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
	defer cancel()

	u, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if u == nil {
		return ErrUsuarioNoExiste
	}

	u.Nombre = strings.TrimSpace(in.Nombre)
	u.Apellido = sql.NullString{String: strings.TrimSpace(in.Apellido), Valid: strings.TrimSpace(in.Apellido) != ""}
	if in.RolID != 0 {
		u.RolID = in.RolID
	}
	u.Activo = in.Activo

	return uc.repo.Update(ctx, *u)
}

func (uc *UserCRUD) Deactivate(ctx context.Context, id uint64, reason string) error {
	ctx, cancel := context.WithTimeout(ctx, 4*time.Second)
	defer cancel()

	u, err := uc.repo.GetByID(ctx, id)
	if err != nil {
		return err
	}
	if u == nil {
		return ErrUsuarioNoExiste
	}

	return uc.repo.Deactivate(ctx, id, reason)
}
