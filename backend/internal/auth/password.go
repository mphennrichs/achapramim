package auth

import "golang.org/x/crypto/bcrypt"

// Política de senha: mínimo 6 caracteres, sem regra de composição.
const MinPasswordLength = 6

func HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

func CheckPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}
