package ports

import (
	"context"

	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/domain"
)

type UserRepository interface {
	Create(ctx context.Context, u domain.User) (uint64, error)
	GetByID(ctx context.Context, id uint64) (*domain.User, error)
	GetByEmail(ctx context.Context, email string) (*domain.User, error)
	List(ctx context.Context, limit, offset int) ([]domain.User, error)
	Update(ctx context.Context, u domain.User) error
	Deactivate(ctx context.Context, id uint64, reason string) error
}
