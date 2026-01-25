package http

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type Deps struct {
	UserHandler *UserHandler
	DBPing      func() error
}

func NewRouter(deps Deps) *gin.Engine {
	r := gin.Default()

	// NO TOCAR: endpoints de salud
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	})
	r.GET("/ready", func(c *gin.Context) {
		if err := deps.DBPing(); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "not-ready", "db": "down"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ready", "db": "up"})
	})

	// CRUD Usuarios
	r.POST("/users", deps.UserHandler.Create)
	r.GET("/users/:id", deps.UserHandler.GetByID)
	r.GET("/users", deps.UserHandler.Get) // ?email= o ?limit=&offset=
	r.PUT("/users/:id", deps.UserHandler.Update)
	r.DELETE("/users/:id", deps.UserHandler.Deactivate)

	return r
}
