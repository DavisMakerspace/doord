pkgname=sentry
pkgver=0
pkgrel=0
pkgdesc="makerspace monitoring and control system"
url=http://davismakerspace.org
arch=(any)
source=(sentry sentry-init.service)
md5sums=(SKIP SKIP)

package() {
  cd $srcdir
  bin=$pkgdir/usr/bin
  sysd=$pkgdir/usr/lib/systemd/system
  install -d $bin
  install -m755 sentry $bin/sentry
  install -d $sysd
  install -m644 sentry-init.service $sysd/sentry-init.service
}
