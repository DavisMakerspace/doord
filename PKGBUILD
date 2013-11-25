pkgname=doord-git
_pkgname=doord
pkgver=$(git --git-dir="$startdir"/.git describe --dirty=-modded | sed 's/-/_/g')
pkgrel=1
pkgdesc='Simple daemon to monitor and control door via GPIO'
url="http://github.com/DavisMakerspace/$_pkgname"
arch=(any)
license=(unknown)
depends=(ruby)
makedepends=()
provides=($_pkgname)
backup=(etc/$_pkgname.conf)
source=()
md5sums=()

prepare() {
  cd "$startdir"
  git checkout-index -a -f --prefix="$srcdir/"
}

build() {
  true
}

check() {
  true
}

package() {
  cd "$srcdir"
  DESTDIR=$pkgdir ./install
}
