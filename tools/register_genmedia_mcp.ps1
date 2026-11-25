param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$GoogleCloudProject,

    [string]$GenMediaBucket,

    [switch]$IncludeVeo
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command codex -ErrorAction SilentlyContinue)) {
    throw "Codex CLI não encontrado. Instale/abra o Codex CLI e tente novamente."
}
if (-not (Get-Command mcp-nanobanana-go -ErrorAction SilentlyContinue)) {
    throw "mcp-nanobanana-go não está no PATH. Instale o binário GenMedia oficial e reabra o terminal."
}
if (-not $env:GOOGLE_APPLICATION_CREDENTIALS) {
    $gcloud = Get-Command gcloud -ErrorAction SilentlyContinue
    if (-not $gcloud) {
        throw "gcloud CLI não encontrado. Configure Google Cloud CLI e ADC antes de registrar o servidor."
    }
    Write-Host "Confirme que ADC está autenticado: gcloud auth application-default login"
}

$registerArgs = @("mcp", "add", "genmedia-nanobanana", "--env", "GOOGLE_CLOUD_PROJECT=$GoogleCloudProject")
if ($GenMediaBucket) {
    $registerArgs += @("--env", "GENMEDIA_BUCKET=$GenMediaBucket")
}
$registerArgs += @("--", "mcp-nanobanana-go")
& codex @registerArgs
if ($LASTEXITCODE -ne 0) { throw "Falha ao registrar GenMedia Nano Banana no Codex." }

if ($IncludeVeo) {
    if (-not (Get-Command mcp-veo-go -ErrorAction SilentlyContinue)) {
        throw "mcp-veo-go não está no PATH. Instale o binário Veo antes de solicitar sua inclusão."
    }
    $veoArgs = @("mcp", "add", "genmedia-veo", "--env", "GOOGLE_CLOUD_PROJECT=$GoogleCloudProject")
    if ($GenMediaBucket) { $veoArgs += @("--env", "GENMEDIA_BUCKET=$GenMediaBucket") }
    $veoArgs += @("--", "mcp-veo-go")
    & codex @veoArgs
    if ($LASTEXITCODE -ne 0) { throw "Falha ao registrar GenMedia Veo no Codex." }
}

Write-Host "Servidores registrados. Verifique com: codex mcp list"
Write-Host "Isso registra os comandos no cliente local; não autentica sua conta Google nem executa geração."
