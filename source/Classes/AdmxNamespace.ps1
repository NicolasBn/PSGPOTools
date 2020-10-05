class AdmxNamespace {
    [string]$prefix
    [string]$namespace

    AdmxNamespace($namesp) {
        $this.prefix = $namesp.prefix
        $this.namespace = $namesp.namespace
    }
}
