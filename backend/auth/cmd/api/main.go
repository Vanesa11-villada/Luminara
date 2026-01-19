package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/Vanesa11-villada/Luminara/backend/auth/config"
	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/infrastructure/db"
)

func main() {
	cfg := config.Load()

	mysqlConn, err := db.NewMySQL(cfg.MySQLDSN())
	if err != nil {
		log.Fatalf("Error conectando a MySQL: %v", err)
	}
	defer func() {
		_ = mysqlConn.Close()
	}()

	log.Println("✅ Conexión a MySQL OK (db_auth)")

	// Endpoints mínimos solo para confirmar vida del servicio
	r := gin.Default()

	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})

	r.GET("/ready", func(c *gin.Context) {
		// Ready = DB responde
		if err := mysqlConn.DB.Ping(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "not-ready", "db": "down"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ready", "db": "up"})
	})

	log.Printf("Auth service escuchando en :%s\n", cfg.AppPort)
	if err := r.Run(":" + cfg.AppPort); err != nil {
		log.Fatalf("Error iniciando servidor: %v", err)
	}
}
