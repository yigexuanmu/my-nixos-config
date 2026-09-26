;;; Minimal Guix Home foundation.
;;; Keep this file as the single entry point.

(use-modules (gnu home)
             (gnu packages)
             (gnu services))

(home-environment
  (packages
    (specifications->packages
      (list
        "glibc-locales"
        "htop"
        "ripgrep"
        "fd")))

  (services
    (list)))
