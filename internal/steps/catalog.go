package steps

var catalog = []Definition{
	{
		ID:           "install-packages",
		Name:         "Install packages",
		Description:  "Installs the baseline system packages required by the setup.",
		Group:        GroupSystem,
		DependsOn:    nil,
		DefaultModes: []Mode{ModeInstall, ModeUpdate},
		Optional:     false,
		Requires: Requirements{
			Root:    true,
			Session: false,
		},
	},
	{
		ID:           "ensure-dotfiles-python-env",
		Name:         "Ensure dotfiles Python env",
		Description:  "Ensures the Python environment used by the dotfiles is available and up to date.",
		Group:        GroupDotfiles,
		DependsOn:    []ID{"install-packages"},
		DefaultModes: []Mode{ModeInstall, ModeUpdate},
		Optional:     false,
		Requires: Requirements{
			Root:    false,
			Session: false,
		},
	},
}

var catalogByID = buildCatalogIndex(catalog)

func All() []Definition {
	return catalog
}

func ByID(id ID) (Definition, bool) {
	def, ok := catalogByID[id]
	return def, ok
}

func buildCatalogIndex(defs []Definition) map[ID]Definition {
	byID := make(map[ID]Definition, len(defs))
	for _, def := range defs {
		byID[def.ID] = def
	}
	return byID
}
