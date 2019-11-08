JOB_NAME="${WORKSPACE_NAME}-${CI_JOB_NAME}"

die() {
    echo "$@" >&2
    exit 1
}

ci_docker() (
    (($# > 0)) || die "${FUNCNAME[0]}: Invalid usage"

    cd $WORKSPACE_DIR

    time docker run --rm --name $JOB_NAME -v ~+:/data -w /data/hare \
         $DOCKER_REGISTRY/mero/hare:$CENTOS_RELEASE "$@"

    # Containers run commands as 'root' user.  Restore the ownership.
    sudo chown -R $(id -u):$(id -g) .
)

ci_m0vg_init() (
    case $# in
        1) local m0vg_dir=m0vg-1node;;
        2) local m0vg_dir=m0vg-2nodes;;
        *) die "Usage: ${FUNCNAME[0]} HOST...";;
    esac

    [[ $M0VG == $m0vg_dir/scripts/m0vg ]] ||
        die "${FUNCNAME[0]}: Impossible happened"

    cd $WORKSPACE_DIR

    if [[ ! -d $m0vg_dir ]]; then
        git clone --recursive --depth 1 --shallow-submodules \
            http://gitlab.mero.colo.seagate.com/mero/mero.git $m0vg_dir
    fi

    $M0VG env add <<EOF
M0_VM_BOX=centos75/dev-halon
M0_VM_BOX_URL='http://ci-storage.mero.colo.seagate.com/vagrant/centos75/dev'
M0_VM_CMU_MEM_MB=4096
M0_VM_NAME_PREFIX=$JOB_NAME
M0_VM_HOSTNAME_PREFIX=$JOB_NAME
EOF

    local host=
    for host in "$@"; do
        time $M0VG up --no-provision $host
        time $M0VG reload --no-provision $host
    done
)