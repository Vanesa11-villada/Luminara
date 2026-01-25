package http

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/Vanesa11-villada/Luminara/backend/auth/internal/usecase"
)

type UserHandler struct {
	uc *usecase.UserCRUD
}

func NewUserHandler(uc *usecase.UserCRUD) *UserHandler {
	return &UserHandler{uc: uc}
}

type createUserRequest struct {
	Nombre   string `json:"nombre"`
	Apellido string `json:"apellido"`
	Email    string `json:"email"`
	Password string `json:"password"`
	RolID    uint8  `json:"rol_id"`
}

func (h *UserHandler) Create(c *gin.Context) {
	var req createUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "json inválido"})
		return
	}

	id, err := h.uc.Create(c.Request.Context(), usecase.CreateUserInput{
		Nombre:   req.Nombre,
		Apellido: req.Apellido,
		Email:    req.Email,
		Password: req.Password,
		RolID:    req.RolID,
	})
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{"id": id})
}

func (h *UserHandler) GetByID(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}

	u, err := h.uc.GetByID(c.Request.Context(), id)
	if err != nil {
		code := http.StatusBadRequest
		if err == usecase.ErrUsuarioNoExiste {
			code = http.StatusNotFound
		}
		c.JSON(code, gin.H{"error": err.Error()})
		return
	}

	// Nunca devolvemos password_hash
	c.JSON(http.StatusOK, gin.H{
		"id": u.ID, "nombre": u.Nombre, "apellido": u.Apellido.String,
		"email": u.Email, "rol_id": u.RolID, "activo": u.Activo,
		"creado_en": u.CreadoEn, "actualizado_en": u.ActualizadoEn,
	})
}

func (h *UserHandler) Get(c *gin.Context) {
	email := c.Query("email")
	if email != "" {
		u, err := h.uc.GetByEmail(c.Request.Context(), email)
		if err != nil {
			code := http.StatusBadRequest
			if err == usecase.ErrUsuarioNoExiste {
				code = http.StatusNotFound
			}
			c.JSON(code, gin.H{"error": err.Error()})
			return
		}
		c.JSON(http.StatusOK, gin.H{
			"id": u.ID, "nombre": u.Nombre, "apellido": u.Apellido.String,
			"email": u.Email, "rol_id": u.RolID, "activo": u.Activo,
			"creado_en": u.CreadoEn, "actualizado_en": u.ActualizadoEn,
		})
		return
	}

	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "50"))
	offset, _ := strconv.Atoi(c.DefaultQuery("offset", "0"))

	users, err := h.uc.List(c.Request.Context(), limit, offset)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "error listando usuarios"})
		return
	}

	out := make([]gin.H, 0, len(users))
	for _, u := range users {
		out = append(out, gin.H{
			"id": u.ID, "nombre": u.Nombre, "apellido": u.Apellido.String,
			"email": u.Email, "rol_id": u.RolID, "activo": u.Activo,
			"creado_en": u.CreadoEn, "actualizado_en": u.ActualizadoEn,
		})
	}
	c.JSON(http.StatusOK, out)
}

type updateUserRequest struct {
	Nombre   string `json:"nombre"`
	Apellido string `json:"apellido"`
	RolID    uint8  `json:"rol_id"`
	Activo   bool   `json:"activo"`
}

func (h *UserHandler) Update(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}

	var req updateUserRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "json inválido"})
		return
	}

	err = h.uc.Update(c.Request.Context(), id, usecase.UpdateUserInput{
		Nombre: req.Nombre, Apellido: req.Apellido, RolID: req.RolID, Activo: req.Activo,
	})
	if err != nil {
		code := http.StatusBadRequest
		if err == usecase.ErrUsuarioNoExiste {
			code = http.StatusNotFound
		}
		c.JSON(code, gin.H{"error": err.Error()})
		return
	}

	c.Status(http.StatusNoContent)
}

func (h *UserHandler) Deactivate(c *gin.Context) {
	id, err := strconv.ParseUint(c.Param("id"), 10, 64)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "id inválido"})
		return
	}

	reason := c.DefaultQuery("reason", "INACTIVIDAD")

	if err := h.uc.Deactivate(c.Request.Context(), id, reason); err != nil {
		code := http.StatusBadRequest
		if err == usecase.ErrUsuarioNoExiste {
			code = http.StatusNotFound
		}
		c.JSON(code, gin.H{"error": err.Error()})
		return
	}
	c.Status(http.StatusNoContent)
}
