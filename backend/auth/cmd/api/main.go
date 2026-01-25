package main

import (
	"log"

	"github.com/Vanesa11-villada/Luminara/backend/auth/config"
	httpDelivery "github.com/Vanesa11-villada/Luminara/backend/auth/internal/delivery/http"
	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/infrastructure/db"
	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/infrastructure/repo"
	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/usecase"
)

func main() {
	cfg := config.Load()

	mysqlConn, err := db.NewMySQL(cfg.MySQLDSN())
	if err != nil {
		log.Fatalf("Error conectando a MySQL: %v", err)
	}
	defer func() { _ = mysqlConn.Close() }()

	log.Println("✅ Conexión a MySQL OK (db_auth)")

	// 1) Repositorios (infra)
	userRepo := repo.NewUserMySQLRepository(mysqlConn.DB)

	// 2) Casos de uso (aplicación)
	userUC := usecase.NewUserCRUD(userRepo)

	// 3) Handlers (delivery)
	userHandler := httpDelivery.NewUserHandler(userUC)

	// 4) Router (HTTP)
	r := httpDelivery.NewRouter(httpDelivery.Deps{
		UserHandler: userHandler,
		DBPing:      mysqlConn.DB.Ping,
	})

	log.Printf("Auth service escuchando en :%s\n", cfg.AppPort)
	if err := r.Run(":" + cfg.AppPort); err != nil {
		log.Fatalf("Error iniciando servidor: %v", err)
	}
}
