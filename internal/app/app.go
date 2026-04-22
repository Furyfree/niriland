package app

import "github.com/Furyfree/niriland/internal/logging"

var logger = logging.New()

// Public function, so uppercase
func RunApp() {
	plan()
}

// Private function, so lowercase
func plan() {
	logger.Info("plan stub reached")
}
