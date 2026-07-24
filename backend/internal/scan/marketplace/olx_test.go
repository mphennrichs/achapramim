package marketplace

import "testing"

func TestBuildOLXSearchURL(t *testing.T) {
	cases := []struct {
		name  string
		query Query
		want  string
	}{
		{
			name:  "region known falls back to city/state path",
			query: Query{Keywords: []string{"frigobar"}, City: "Belo Horizonte", State: "MG"},
			want:  "https://www.olx.com.br/minas-gerais/belo-horizonte?q=frigobar",
		},
		{
			name:  "unknown state falls back to national search",
			query: Query{Keywords: []string{"frigobar"}, City: "Curitiba", State: "PR"},
			want:  "https://www.olx.com.br/brasil?q=frigobar",
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
