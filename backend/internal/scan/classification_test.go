package scan

import "testing"

func TestKeywordMatchRatio(t *testing.T) {
	tests := []struct {
		name     string
		title    string
		keywords []string
		want     float64
	}{
		{"no keywords means full score", "qualquer coisa", nil, 1},
		{"all keywords match", "PlayStation 5 novo lacrado", []string{"playstation", "5"}, 1},
		{"half keywords match", "PlayStation 4 usado", []string{"playstation", "5"}, 0.5},
		{"case insensitive", "PLAYSTATION 5", []string{"playstation"}, 1},
		{"no match", "Xbox Series X", []string{"playstation"}, 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := keywordMatchRatio(tt.title, tt.keywords)
			if got != tt.want {
				t.Errorf("keywordMatchRatio() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestMatchesAllKeywords(t *testing.T) {
	tests := []struct {
		name     string
		title    string
		keywords []string
		want     bool
	}{
		{"no keywords always matches", "qualquer coisa", nil, true},
		{"all keywords present", "PlayStation 5 novo lacrado", []string{"playstation", "5"}, true},
		{"missing one keyword", "PlayStation 4 usado", []string{"playstation", "5"}, false},
		{"case insensitive", "PLAYSTATION 5", []string{"playstation", "5"}, true},
		{"no match at all", "Xbox Series X", []string{"playstation"}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := matchesAllKeywords(tt.title, tt.keywords)
			if got != tt.want {
				t.Errorf("matchesAllKeywords() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestMatchesAnyKeyword(t *testing.T) {
	tests := []struct {
		name     string
		title    string
		keywords []string
		want     bool
	}{
		{"no keywords always matches", "qualquer coisa", nil, true},
		{"all keywords present", "PlayStation 5 novo lacrado", []string{"playstation", "5"}, true},
		{"one keyword present", "PlayStation 4 usado", []string{"playstation", "5"}, true},
		{"case insensitive", "PLAYSTATION 4", []string{"playstation"}, true},
		{"no match at all", "Xbox Series X", []string{"playstation", "5"}, false},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := matchesAnyKeyword(tt.title, tt.keywords)
			if got != tt.want {
				t.Errorf("matchesAnyKeyword() = %v, want %v", got, tt.want)
			}
		})
	}
}

func TestContainsBlockedWord(t *testing.T) {
	if !containsBlockedWord("PS5 quebrado, para peças", []string{"quebrado"}) {
		t.Error("expected blocked word to be detected")
	}
	if containsBlockedWord("PS5 novo lacrado", []string{"quebrado"}) {
		t.Error("did not expect blocked word to be detected")
	}
	if !containsBlockedWord("PS5 QUEBRADO", []string{"quebrado"}) {
		t.Error("expected case-insensitive match")
	}
}

func TestPriceProximityScore(t *testing.T) {
	tests := []struct {
		name             string
		targetPriceCents int64
		tolerancePercent float64
		priceCents       int64
		want             float64
	}{
		{"exact match", 250000, 10, 250000, 1},
		{"at tolerance edge", 250000, 10, 275000, 0},
		{"beyond tolerance", 250000, 10, 300000, 0},
		{"halfway to edge", 250000, 10, 262500, 0.5},
		{"zero target", 0, 10, 100, 0},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := priceProximityScore(tt.targetPriceCents, tt.tolerancePercent, tt.priceCents)
			if got != tt.want {
				t.Errorf("priceProximityScore() = %v, want %v", got, tt.want)
			}
		})
	}
}
