/// Páginas do shell principal (sidebar), na ordem em que aparecem no menu —
/// o índice nesta lista é o `branchIndex` usado por `navigationShell.goBranch`.
enum NavigationPage {
  watches,
  watchDetail,
  newWatch,
  profile;

  String get path => switch (this) {
        NavigationPage.watches => '/watches',
        NavigationPage.watchDetail => ':watchId',
        NavigationPage.newWatch => '/watches/new',
        NavigationPage.profile => '/profile',
      };
}
