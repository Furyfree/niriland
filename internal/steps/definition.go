package steps

type ID string
type Group string
type Mode string

const (
	ModeInstall Mode = "install"
	ModeUpdate  Mode = "update"
)

const (
	GroupDotfiles Group = "dotfiles"
	GroupSystem   Group = "system"
)

type Requirements struct {
	Root    bool
	Session bool
}

type Definition struct {
	ID           ID
	Name         string
	Description  string
	Group        Group
	DependsOn    []ID
	DefaultModes []Mode
	Optional     bool
	Requires     Requirements
}
