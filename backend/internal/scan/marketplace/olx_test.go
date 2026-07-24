package marketplace

import "testing"

func TestBuildOLXSearchURL(t *testing.T) {
	cases := []struct {
		name  string
		query Query
		want  string
	}{
		{
			name:  "state present scopes search to that state",
			query: Query{Keywords: []string{"frigobar"}, City: "Belo Horizonte", State: "MG"},
			want:  "https://www.olx.com.br/brasil/estado-mg?q=frigobar",
		},
		{
			name:  "state present without city still scopes to state",
			query: Query{Keywords: []string{"frigobar"}, State: "PR"},
			want:  "https://www.olx.com.br/brasil/estado-pr?q=frigobar",
		},
		{
			name:  "no region set falls back to national search",
			query: Query{Keywords: []string{"frigobar"}},
			want:  "https://www.olx.com.br/brasil?q=frigobar",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := buildOLXSearchURL(tc.query)
			if got != tc.want {
				t.Errorf("buildOLXSearchURL() = %q, want %q", got, tc.want)
			}
		})
	}
}
