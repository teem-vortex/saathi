param(
    [string]$SupabaseUrl = 'https://faegnqoyqwnrfiixbhfz.supabase.co',
    [string]$SupabaseAnonKey = $env:SUPABASE_ANON_KEY
)

$ErrorActionPreference = 'Stop'
$firebasePath = Join-Path $PSScriptRoot '..\android\app\google-services.json'
if (-not (Test-Path -LiteralPath $firebasePath)) {
    throw "Missing $firebasePath. Download google-services.json for com.example.saathi from Firebase."
}
if ([string]::IsNullOrWhiteSpace($SupabaseAnonKey)) {
    throw 'Set SUPABASE_ANON_KEY to the Supabase publishable/anon key before building.'
}

$firebase = Get-Content -LiteralPath $firebasePath -Raw | ConvertFrom-Json
$client = $firebase.client | Where-Object {
    $_.client_info.android_client_info.package_name -eq 'com.example.saathi'
} | Select-Object -First 1
if ($null -eq $client) {
    throw 'google-services.json does not contain the com.example.saathi Android client.'
}

flutter build apk --debug `
    --dart-define="SUPABASE_URL=$SupabaseUrl" `
    --dart-define="SUPABASE_ANON_KEY=$SupabaseAnonKey" `
    --dart-define="FIREBASE_API_KEY=$($client.api_key[0].current_key)" `
    --dart-define="FIREBASE_APP_ID=$($client.client_info.mobilesdk_app_id)" `
    --dart-define="FIREBASE_MESSAGING_SENDER_ID=$($firebase.project_info.project_number)" `
    --dart-define="FIREBASE_PROJECT_ID=$($firebase.project_info.project_id)"
